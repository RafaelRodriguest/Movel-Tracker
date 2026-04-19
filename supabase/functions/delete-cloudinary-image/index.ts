import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  let publicId: string;
  try {
    const body = await req.json();
    publicId = body.public_id;
    if (!publicId) throw new Error("missing public_id");
  } catch {
    return new Response(JSON.stringify({ error: "public_id required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const cloudName = Deno.env.get("CLOUDINARY_CLOUD_NAME");
  const apiKey = Deno.env.get("CLOUDINARY_API_KEY");
  const apiSecret = Deno.env.get("CLOUDINARY_API_SECRET");

  if (!cloudName || !apiKey || !apiSecret) {
    return new Response(JSON.stringify({ error: "Server misconfigured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const timestamp = Math.round(Date.now() / 1000);
  const signatureStr = `public_id=${publicId}&timestamp=${timestamp}${apiSecret}`;

  const encoded = new TextEncoder().encode(signatureStr);
  const hashBuffer = await crypto.subtle.digest("SHA-1", encoded);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const signature = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

  const formData = new FormData();
  formData.append("public_id", publicId);
  formData.append("api_key", apiKey);
  formData.append("timestamp", String(timestamp));
  formData.append("signature", signature);

  const cloudinaryRes = await fetch(
    `https://api.cloudinary.com/v1_1/${cloudName}/image/destroy`,
    { method: "POST", body: formData },
  );

  const result = await cloudinaryRes.json();
  return new Response(JSON.stringify(result), {
    status: cloudinaryRes.status,
    headers: { "Content-Type": "application/json" },
  });
});
