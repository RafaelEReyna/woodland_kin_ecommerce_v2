import type { Context } from "@netlify/functions";
import Stripe from "stripe";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2025-01-27.acacia",
});

interface CartItem {
  variantId: string;
  designName: string;
  productType: string;
  color: string;
  size: string;
  price: number;
  qty: number;
}

interface RequestBody {
  items: CartItem[];
  cartTotal: number;
}

const PRODUCT_TYPE_LABELS: Record<string, string> = {
  tee: "Tee",
  long_sleeve: "Long Sleeve",
  hoodie: "Hoodie",
};

export default async (req: Request, context: Context) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { items, cartTotal }: RequestBody = await req.json();

    if (!items || items.length === 0) {
      return new Response(JSON.stringify({ error: "Cart is empty" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const line_items: Stripe.Checkout.SessionCreateParams.LineItem[] =
      items.map((item) => ({
        price_data: {
          currency: "usd",
          unit_amount: item.price,
          product_data: {
            name: `${item.designName} — ${PRODUCT_TYPE_LABELS[item.productType] || item.productType} / ${item.color} / ${item.size}`,
            metadata: { variantId: item.variantId },
          },
        },
        quantity: item.qty,
      }));

    const FREE_SHIPPING_THRESHOLD = 10000;
    const shipping_options: Stripe.Checkout.SessionCreateParams.ShippingOption[] =
      cartTotal >= FREE_SHIPPING_THRESHOLD
        ? [
            {
              shipping_rate_data: {
                type: "fixed_amount",
                fixed_amount: { amount: 0, currency: "usd" },
                display_name: "Free Shipping",
              },
            },
          ]
        : [
            {
              shipping_rate_data: {
                type: "fixed_amount",
                fixed_amount: { amount: 799, currency: "usd" },
                display_name: "Standard Shipping",
              },
            },
          ];

    const siteUrl = process.env.PUBLIC_SITE_URL || "http://localhost:8888";

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items,
      shipping_options,
      shipping_address_collection: { allowed_countries: ["US"] },
      success_url: `${siteUrl}/order/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${siteUrl}/order/cancel`,
    });

    return new Response(JSON.stringify({ url: session.url }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
};
