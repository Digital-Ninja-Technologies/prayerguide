// Supabase Edge Function: proxies the AI Prayer Assistant to the Claude API.
//
// The Anthropic API key lives ONLY here, as a Supabase secret
// (`supabase secrets set ANTHROPIC_API_KEY=sk-ant-...`) — it is never sent to
// or stored in the Flutter app. The app calls this function with the
// caller's Supabase auth JWT; we verify it, then forward the chat to Claude.
//
// Deploy with: supabase functions deploy assistant-proxy

import { createClient } from "jsr:@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const SYSTEM_PROMPT = `You are the Prayer Guide app's Prayer Assistant. You help \
a Christian user pray, reflect on Scripture, and process what's on their heart. \
You are here to help them pray, not replace their own prayer life. Keep a warm, \
calm, reverent, non-denominational tone. Ground suggestions in Scripture \
(public-domain KJV/WEB citations are safe to quote directly). Keep replies \
concise — a few short paragraphs at most. Never give medical, legal, or \
crisis-counseling advice; gently point to a pastor, counselor, or emergency \
services if the user describes a crisis.`;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }
  if (!ANTHROPIC_API_KEY) {
    return new Response(
      JSON.stringify({ error: "ANTHROPIC_API_KEY is not configured on this function." }),
      { status: 500, headers: { "content-type": "application/json" } },
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
      status: 401,
      headers: { "content-type": "application/json" },
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userErr } = await supabase.auth.getUser();
  if (userErr || !userData?.user) {
    return new Response(JSON.stringify({ error: "Invalid or expired session" }), {
      status: 401,
      headers: { "content-type": "application/json" },
    });
  }

  const { messages } = await req.json();
  if (!Array.isArray(messages)) {
    return new Response(JSON.stringify({ error: "Body must include a `messages` array" }), {
      status: 400,
      headers: { "content-type": "application/json" },
    });
  }

  const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-5",
      max_tokens: 600,
      system: SYSTEM_PROMPT,
      messages,
    }),
  });

  const body = await anthropicRes.text();
  return new Response(body, {
    status: anthropicRes.status,
    headers: { "content-type": "application/json" },
  });
});
