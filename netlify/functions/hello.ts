import type { Context } from "@netlify/functions";

export default async (req: Request, context: Context) => {
  return new Response(
    JSON.stringify({ message: "Woodland Kin API is running" }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    }
  );
};
