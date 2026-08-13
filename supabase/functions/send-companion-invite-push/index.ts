// Sends a push notification to a companion when the other side of the pair
// taps "Pray live" (companion_detail_screen.dart), so they find out even if
// they're not currently in the app. Uses Firebase Cloud Messaging's HTTP v1
// API — the old server-key "legacy" FCM API this could otherwise use with a
// single static key has been shut down by Google, so this signs its own
// short-lived OAuth2 access token from a service account instead.
//
// Deploy: `supabase functions deploy send-companion-invite-push`
// Secrets: `supabase secrets set FIREBASE_SERVICE_ACCOUNT='<service-account-json>'`
// (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY are provided
// automatically.)

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

/// Exchanges the service account's private key for a short-lived OAuth2
/// access token scoped to Firebase Cloud Messaging (a signed JWT-bearer
/// assertion, per Google's server-to-server OAuth2 flow).
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

/// Sends one push via FCM's HTTP v1 API. Returns the raw Response so the
/// caller can tell an UNREGISTERED token (404) apart from any other
/// failure, and clean it up.
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

  let inviteId: string
  try {
    const body = await req.json()
    inviteId = body.inviteId
    if (!inviteId || typeof inviteId !== 'string') throw new Error('missing inviteId')
  } catch {
    return new Response(JSON.stringify({ error: 'inviteId is required' }), { status: 400 })
  }

  // Read with the caller's own token — RLS already limits this to invites
  // for a pair they're actually in, so this alone confirms they're really
  // the requester on this specific invite.
  const { data: invite } = await supabase
    .from('companion_prayer_invites')
    .select('id, companion_id, requester_id, status')
    .eq('id', inviteId)
    .maybeSingle()

  if (!invite || invite.requester_id !== uid) {
    return new Response(JSON.stringify({ error: 'Invite not found.' }), { status: 404 })
  }

  const { data: companion } = await supabase
    .from('companions')
    .select('user_a, user_b')
    .eq('id', invite.companion_id)
    .maybeSingle()
  if (!companion) {
    return new Response(JSON.stringify({ error: 'Companion pair not found.' }), { status: 404 })
  }
  const otherUserId = companion.user_a === uid ? companion.user_b : companion.user_a

  const { data: profile } = await supabase
    .from('profiles')
    .select('name')
    .eq('id', uid)
    .maybeSingle()
  const name = (profile?.name as string | undefined)?.trim() || 'Your companion'

  // Looking up *someone else's* device token needs the service-role client
  // — device_push_tokens is owner-only RLS, and this is sending on behalf
  // of the other side of the pair, not the caller.
  const service = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
  const { data: tokens } = await service
    .from('device_push_tokens')
    .select('token')
    .eq('user_id', otherUserId)

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
      `${name} wants to pray with you`,
      'Tap to join them now.',
      { type: 'companion_prayer_invite', inviteId: invite.id, companionId: invite.companion_id },
    )
    if (res.ok) {
      sent++
    } else if (res.status === 404) {
      // UNREGISTERED — the app was uninstalled or the token rotated.
      await service.from('device_push_tokens').delete().eq('token', token)
    }
  }

  return new Response(JSON.stringify({ sent }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
