import type { OrderData } from "./order-utils";
import { getPrintfulVariantId } from "../data/printful-map";

interface PrintfulResult {
  success: boolean;
  printfulOrderId?: number;
  error?: string;
}

export async function createPrintfulOrder(
  orderData: OrderData
): Promise<PrintfulResult> {
  const apiKey = process.env.PRINTFUL_API_KEY;
  if (!apiKey) {
    return { success: false, error: "PRINTFUL_API_KEY not configured" };
  }

  const address = orderData.shipping.address;
  if (!address) {
    return { success: false, error: "No shipping address provided" };
  }

  const items = orderData.items
    .map((item) => {
      // Extract variantId from the line item description if available
      // In production, pass metadata through Stripe line items
      return {
        sync_variant_id: 0, // Will be mapped from metadata
        quantity: item.quantity || 1,
        retail_price: item.amount_total
          ? (item.amount_total / 100).toFixed(2)
          : "0.00",
      };
    })
    .filter((item) => item.sync_variant_id > 0);

  const body = {
    external_id: orderData.orderId,
    recipient: {
      name: orderData.shipping.name || "",
      address1: address.line1 || "",
      address2: address.line2 || "",
      city: address.city || "",
      state_code: address.state || "",
      country_code: address.country || "US",
      zip: address.postal_code || "",
      email: orderData.email,
    },
    items,
  };

  try {
    const res = await fetch("https://api.printful.com/orders", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const errorBody = await res.text();
      console.error("[Printful] Order creation failed:", errorBody);
      return { success: false, error: `Printful API error: ${res.status}` };
    }

    const data = await res.json();
    return { success: true, printfulOrderId: data.result?.id };
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("[Printful] Order creation error:", message);
    return { success: false, error: message };
  }
}
