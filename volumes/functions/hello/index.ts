// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment

Deno.serve(async (_req: Request) => {
  return new Response(JSON.stringify({ message: "Hello from Edge Functions!" }), {
    headers: { "Content-Type": "application/json" },
  })
})

// To invoke:
// curl -s "${SUPABASE_PUBLIC_URL}/functions/v1/hello" \
//   --header "Authorization: Bearer <anon/service_role API key>"
