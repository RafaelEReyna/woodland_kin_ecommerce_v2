import type { Context } from "@netlify/functions";
import { trackEvent } from "../../src/lib/klaviyo";

export default async (req: Request, context: Context) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const body = await req.json();

    if (body.type === "package_shipped") {
      const shipment = body.data?.shipment;
      const trackingNumber = shipment?.tracking_number || null;
      const carrier = shipment?.carrier || null;
      const orderId = shipment?.order?.external_id || null;

      console.error("[Printful Shipped]", JSON.stringify({
        orderId,
        trackingNumber,
        carrier,
      }));

      // Track shipping in Klaviyo
      const customerEmail = shipment?.order?.recipient?.email;
      if (customerEmail) {
        await trackEvent("Order Shipped", customerEmail, {
          trackingNumber,
          carrier,
          orderId,
        });
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("[Printful Webhook Error]", message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
};
