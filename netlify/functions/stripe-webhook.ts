import type { Context } from "@netlify/functions";
import Stripe from "stripe";
import { formatOrderForLog } from "../../src/lib/order-utils";
import { createPrintfulOrder } from "../../src/lib/printful";
import { trackEvent } from "../../src/lib/klaviyo";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2025-01-27.acacia",
});

export default async (req: Request, context: Context) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const sig = req.headers.get("stripe-signature");
  if (!sig) {
    return new Response(JSON.stringify({ error: "Missing signature" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const body = await req.text();

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : "Verification failed";
    return new Response(JSON.stringify({ error: message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object as Stripe.Checkout.Session;

    const lineItems = await stripe.checkout.sessions.listLineItems(session.id);
    const orderData = formatOrderForLog(session, lineItems.data);

    console.log("[Order Received]", JSON.stringify(orderData, null, 2));

    // Forward to Printful
    const printfulResult = await createPrintfulOrder(orderData);
    console.log("[Printful]", JSON.stringify(printfulResult));
    // TODO: implement retry queue for failed Printful orders

    // Track in Klaviyo
    await trackEvent("Placed Order", orderData.email, {
      orderId: orderData.orderId,
      total: orderData.total ? orderData.total / 100 : 0,
      items: orderData.items,
    });
  }

  return new Response(JSON.stringify({ received: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};
