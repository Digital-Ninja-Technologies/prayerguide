// Accepting a shared sermon note produces a fully independent copy for the
// recipient — a new sermon_notes row they own, plus a copy of every
// recording's audio file under their own storage folder. That last part is
// why this has to be an Edge Function rather than a plain SQL RPC: copying
// an object between two different users' folders in the private
// "sermon-audio" bucket needs the Storage API under a service-role client
// (RLS would block a client-side copy across users' folders), the same
// "authorize with the caller's own client, then do the privileged work with
// a service-role client" shape as send-companion-invite-push/index.ts.
//
// Deploy: `supabase functions deploy accept-sermon-share`
// (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY are provided
// automatically.)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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
  // addressed to them, and the explicit status/recipient checks below prove
  // this is really theirs to accept, and not already responded to.
  const { data: share } = await supabase
    .from('sermon_shares')
    .select('id, sermon_note_id, sender_id, recipient_id, status')
    .eq('id', shareId)
    .eq('recipient_id', uid)
    .eq('status', 'pending')
    .maybeSingle()

  if (!share) {
    return new Response(JSON.stringify({ error: 'Share not found.' }), { status: 404 })
  }

  const service = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { data: sourceNote, error: sourceNoteError } = await service
    .from('sermon_notes')
    .select('title, speaker, scripture_ref, notes')
    .eq('id', share.sermon_note_id)
    .single()
  if (sourceNoteError || !sourceNote) {
    return new Response(JSON.stringify({ error: 'Original sermon note no longer exists.' }), {
      status: 404,
    })
  }

  const { data: sourceRecordings } = await service
    .from('sermon_note_recordings')
    .select('id, audio_path, duration_seconds')
    .eq('sermon_note_id', share.sermon_note_id)

  const { data: senderProfile } = await service
    .from('profiles')
    .select('name')
    .eq('id', share.sender_id)
    .maybeSingle()

  const { data: newNote, error: insertNoteError } = await service
    .from('sermon_notes')
    .insert({
      user_id: share.recipient_id,
      title: sourceNote.title,
      speaker: sourceNote.speaker,
      scripture_ref: sourceNote.scripture_ref,
      notes: sourceNote.notes,
      shared_from_user_id: share.sender_id,
      shared_from_name: (senderProfile?.name as string | undefined)?.trim() || null,
    })
    .select('id')
    .single()
  if (insertNoteError || !newNote) {
    return new Response(JSON.stringify({ error: 'Could not create the copy.' }), { status: 500 })
  }

  for (const recording of sourceRecordings ?? []) {
    const newRecordingId = crypto.randomUUID()
    const newPath = `${share.recipient_id}/${newNote.id}/${newRecordingId}.m4a`
    const { error: copyError } = await service.storage
      .from('sermon-audio')
      .copy(recording.audio_path as string, newPath)
    if (copyError) continue // best-effort per take — one bad file shouldn't sink the whole accept

    await service.from('sermon_note_recordings').insert({
      id: newRecordingId,
      sermon_note_id: newNote.id,
      audio_path: newPath,
      duration_seconds: recording.duration_seconds,
    })
  }

  await service
    .from('sermon_shares')
    .update({ status: 'accepted', responded_at: new Date().toISOString() })
    .eq('id', shareId)

  return new Response(JSON.stringify({ sermonNoteId: newNote.id }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
