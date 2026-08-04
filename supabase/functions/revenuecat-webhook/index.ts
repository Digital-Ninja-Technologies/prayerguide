// Syncs the `subscriptions` table from RevenueCat's server-to-server
// webhook — the only path allowed to write `tier` (see migration
// 0016_security_audit_fixes.sql). Previously the Flutter app wrote its own
// RevenueCat CustomerInfo straight into `subscriptions`, but a client can
// call Supabase's REST API directly with any JSON it likes, so that write
// was equivalent to letting any user grant themselves Premium for free.
// A webhook driven by RevenueCat's own servers, verified with a shared
// secret only RevenueCat and this function know, can't be forged that way.
//
// Deploy: `supabase functions deploy revenuecat-webhook --no-verify-jwt`
// (RevenueCat calls this anonymously and authenticates via the header
// below instead of a Supabase user JWT.)
// Secrets: `supabase secrets set REVENUECAT_WEBHOOK_AUTH=<a random string>`
// (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically.)
//
// Then in the RevenueCat dashboard: Project Settings → Integrations →
// Webhooks — set the URL to this function's endpoint and the
// "Authorization header value" to the same REVENUECAT_WEBHOOK_AUTH string.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const WEBHOOK_AUTH = Deno.env.get('REVENUECAT_WEBHOOK_AUTH')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// Must match kPremiumEntitlementId in lib/core/purchases/revenue_cat_service.dart.
const PREMIUM_ENTITLEMENT = 'PrayerGuide'

// Events that mean the entitlement is (still) active.
const PREMIUM_EVENT_TYPES = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'PRODUCT_CHANGE',
  'UNCANCELLATION',
  'SUBSCRIPTION_EXTENDED',
  // A TRANSFER's app_user_id is the receiving account; the losing side
  // isn't handled here since this app never merges/transfers accounts.
  'TRANSFER',
])
// Events that mean it has actually lapsed. CANCELLATION and BILLING_ISSUE
// are deliberately excluded — the subscription is still active until its
// current period ends, at which point RevenueCat sends EXPIRATION.
const FREE_EVENT_TYPES = new Set(['EXPIRATION'])

function storeToProvider(store: string | undefined): string | null {
  switch (store) {
    case 'APP_STORE':
      return 'app_store'
    case 'PLAY_STORE':
      return 'play_store'
    case 'STRIPE':
      return 'stripe'
    default:
      return store?.toLowerCase() ?? null
  }
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405 })
  }

  if (!WEBHOOK_AUTH || req.headers.get('Authorization') !== WEBHOOK_AUTH) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 })
  }

  let event: Record<string, unknown>
  try {
    const body = await req.json()
    event = body.event
    if (!event || typeof event !== 'object') throw new Error('missing event')
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid payload' }), { status: 400 })
  }

  const type = event.type as string | undefined
  const appUserId = event.app_user_id as string | undefined
  const entitlementIds =
    (event.entitlement_ids as string[] | undefined) ??
    (event.entitlement_id ? [event.entitlement_id as string] : [])

  if (!appUserId || !type) {
    return new Response(JSON.stringify({ error: 'Missing app_user_id or type' }), { status: 400 })
  }

  // Events about a different entitlement/product entirely don't move the
  // needle for our one Premium flag — acknowledge and skip.
  if (!entitlementIds.includes(PREMIUM_ENTITLEMENT)) {
    return new Response(JSON.stringify({ ok: true, skipped: 'not our entitlement' }))
  }

  let tier: 'free' | 'premium' | null = null
  if (PREMIUM_EVENT_TYPES.has(type)) tier = 'premium'
  else if (FREE_EVENT_TYPES.has(type)) tier = 'free'
  if (tier === null) {
    return new Response(JSON.stringify({ ok: true, skipped: `type ${type} does not change tier` }))
  }

  const expirationMs = event.expiration_at_ms as number | undefined
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  const { error } = await supabase.from('subscriptions').upsert({
    user_id: appUserId,
    tier,
    provider: storeToProvider(event.store as string | undefined),
    renews_at: tier === 'premium' && expirationMs ? new Date(expirationMs).toISOString() : null,
    updated_at: new Date().toISOString(),
  })

  if (error) {
    console.error('subscriptions upsert failed', error)
    return new Response(JSON.stringify({ error: 'Failed to sync subscription' }), { status: 500 })
  }

  return new Response(JSON.stringify({ ok: true }))
})
