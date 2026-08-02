// Mints a LiveKit access token for a group's Audio Prayer Room.
//
// This exists so the LiveKit API key/secret never ship inside the Flutter
// app — a client-embedded secret could be extracted from the app bundle
// and used to mint tokens for *any* room. Here the secret stays as an Edge
// Function secret, and every request is checked against real group
// membership before a token is issued.
//
// Deploy: `supabase functions deploy livekit-token`
// Secrets: `supabase secrets set LIVEKIT_API_KEY=... LIVEKIT_API_SECRET=...`
// (SUPABASE_URL and SUPABASE_ANON_KEY are provided automatically.)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const LIVEKIT_API_KEY = Deno.env.get('LIVEKIT_API_KEY')!
const LIVEKIT_API_SECRET = Deno.env.get('LIVEKIT_API_SECRET')!

function base64url(bytes: Uint8Array): string {
  let str = ''
  for (const b of bytes) str += String.fromCharCode(b)
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

async function signLiveKitToken(payload: Record<string, unknown>): Promise<string> {
  const encoder = new TextEncoder()
  const headerB64 = base64url(encoder.encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' })))
  const payloadB64 = base64url(encoder.encode(JSON.stringify(payload)))
  const signingInput = `${headerB64}.${payloadB64}`

  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(LIVEKIT_API_SECRET),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(signingInput))
  return `${signingInput}.${base64url(new Uint8Array(signature))}`
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

  let groupId: string
  try {
    const body = await req.json()
    groupId = body.groupId
    if (!groupId || typeof groupId !== 'string') throw new Error('missing groupId')
  } catch {
    return new Response(JSON.stringify({ error: 'groupId is required' }), { status: 400 })
  }

  // Only members of this group may join its audio room.
  const { data: membership } = await supabase
    .from('group_members')
    .select('group_id')
    .eq('group_id', groupId)
    .eq('user_id', uid)
    .maybeSingle()

  if (!membership) {
    return new Response(
      JSON.stringify({ error: 'You are not a member of this group.' }),
      { status: 403 },
    )
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('name')
    .eq('id', uid)
    .maybeSingle()
  const name = (profile?.name as string | undefined)?.trim() || 'Guest'

  const now = Math.floor(Date.now() / 1000)
  const token = await signLiveKitToken({
    iss: LIVEKIT_API_KEY,
    sub: uid,
    iat: now,
    nbf: now,
    exp: now + 60 * 60, // 1 hour
    name,
    video: {
      room: `room-${groupId}`,
      roomJoin: true,
      canPublish: true,
      canSubscribe: true,
    },
  })

  return new Response(JSON.stringify({ token }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
