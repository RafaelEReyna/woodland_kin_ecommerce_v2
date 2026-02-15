import type Stripe from "stripe";

export interface OrderData {
  orderId: string;
  email: string;
  items: Array<{
    description: string | null;
    quantity: number | null;
    amount_total: number | null;
  }>;
  shipping: {
    name: string | null;
    address: Stripe.Address | null;
  };
  total: number | null;
  timestamp: number;
}

export function formatOrderForLog(
  session: Stripe.Checkout.Session,
  lineItems: Stripe.LineItem[]
): OrderData {
  return {
    orderId: session.id,
    email: session.customer_details?.email || "",
    items: lineItems.map((item) => ({
      description: item.description,
      quantity: item.quantity,
      amount_total: item.amount_total,
    })),
    shipping: {
      name: session.shipping_details?.name || null,
      address: session.shipping_details?.address || null,
    },
    total: session.amount_total,
    timestamp: session.created,
  };
}
