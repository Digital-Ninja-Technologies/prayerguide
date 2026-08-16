// Sends a push notification to the recipient of a sermon share, so they
// find out even if they're not currently in the app. Adapted from
// send-companion-invite-push/index.ts — same FCM HTTP v1 + service-account
// OAuth2 flow, just looking up sermon_shares instead of
// companion_prayer_invites.
//
// Deploy: `supabase functions deploy send-sermon-share-push`
// Secrets: reuses the same FIREBASE_SERVICE_ACCOUNT secret as
// send-companion-invite-push. (SUPABASE_URL, SUPABASE_ANON_KEY,
// SUPABASE_SERVICE_ROLE_KEY are provided automatically.)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const FIREBASE_SERVICE_ACCOUNT = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}')

function base64url(input: Uint8Array | string): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input
  let str = ''
  for (const b of bytes) str += String.fromCharCode(b)
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const clean = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '')
  const raw = Uint8Array.from(atob(clean), (c) => c.charCodeAt(0))
  return crypto.subtle.importKey(
    'pkcs8',
    raw,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = { alg: 'RS256', typ: 'JWT' }
  const claims = {
    iss: FIREBASE_SERVICE_ACCOUNT.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }
  const signingInput =
    `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`
  const key = await importPrivateKey(FIREBASE_SERVICE_ACCOUNT.private_key)
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  )
  const jwt = `${signingInput}.${base64url(new Uint8Array(signature))}`

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })
  if (!res.ok) throw new Error(`FCM token exchange failed: ${await res.text()}`)
  const json = await res.json()
  return json.access_token as string
}

async function sendPush(
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<Response> {
  return fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_SERVICE_ACCOUNT.project_id}/messages:send`,
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: { token, notification: { title, body }, data } }),
    },
  )
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405 })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { status: 401 })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  )

  const { data: userData, error: userError } = await supabase.auth.getUser()
  if (userError || !userData.user) {
    return new Response(JSON.stringify({ error: 'Not authenticated' }), { status: 401 })
  }
  const uid = userData.user.id

  let shareId: string
  try {
    const body = await req.json()
    shareId = body.shareId
    if (!shareId || typeof shareId !== 'string') throw new Error('missing shareId')
  } catch {
    return new Response(JSON.stringify({ error: 'shareId is required' }), { status: 400 })
  }

  // Read with the caller's own token — RLS already limits this to shares
  // they sent or received, so requiring sender_id === uid below confirms
  // they're really the one who just created this share.
  const { data: share } = await supabase
    .from('sermon_shares')
    .select('id, sender_id, recipient_id, sermon_notes(title)')
    .eq('id', shareId)
    .maybeSingle()

  if (!share || share.sender_id !== uid) {
    return new Response(JSON.stringify({ error: 'Share not found.' }), { status: 404 })
  }
  const sermonTitle =
    (share.sermon_notes as { title?: string } | { title?: string }[] | null | undefined) &&
    (Array.isArray(share.sermon_notes) ? share.sermon_notes[0]?.title : share.sermon_notes?.title)

  const { data: profile } = await supabase
    .from('profiles')
    .select('name')
    .eq('id', uid)
    .maybeSingle()
  const name = (profile?.name as string | undefined)?.trim() || 'Someone'

  // Looking up *someone else's* device token needs the service-role client
  // — device_push_tokens is owner-only RLS, and this sends to the
  // recipient, not the caller.
  const service = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
  const { data: tokens } = await service
    .from('device_push_tokens')
    .select('token')
    .eq('user_id', share.recipient_id)

  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }), {
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const accessToken = await getAccessToken()
  let sent = 0
  for (const row of tokens) {
    const token = row.token as string
    const res = await sendPush(
      accessToken,
      token,
      `${name} shared a sermon note with you`,
      sermonTitle ? String(sermonTitle) : 'Tap to view it.',
      { type: 'sermon_share', shareId: share.id },
    )
    if (res.ok) {
      sent++
    } else if (res.status === 404) {
      await service.from('device_push_tokens').delete().eq('token', token)
    }
  }

  return new Response(JSON.stringify({ sent }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
