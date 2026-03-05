import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const FUNCTIONS_PATH = "/home/deno/functions";

serve(async (req: Request) => {
  const url = new URL(req.url);
  const pathParts = url.pathname.split("/").filter(Boolean);

  if (pathParts.length === 0) {
    return new Response(JSON.stringify({ error: "Function name required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const functionName = pathParts[0];
  const functionPath = `${FUNCTIONS_PATH}/${functionName}/index.ts`;

  try {
    const mod = await import(functionPath);
    return mod.default(req);
  } catch (e) {
    return new Response(
      JSON.stringify({ error: `Function '${functionName}' not found` }),
      { status: 404, headers: { "Content-Type": "application/json" } }
    );
  }
});
