import { useEffect, useState } from "react";
import { useStore } from "@nanostores/react";
import { $cart, $cartTotal, $freeShippingRemaining, removeFromCart, updateQty } from "../stores/cart";
import { formatPrice, FREE_SHIPPING_THRESHOLD } from "../lib/pricing";

export default function CartDrawer() {
  const [open, setOpen] = useState(false);
  const [checkoutLoading, setCheckoutLoading] = useState(false);
  const [checkoutError, setCheckoutError] = useState("");
  const items = useStore($cart);
  const total = useStore($cartTotal);
  const freeShippingRemaining = useStore($freeShippingRemaining);

  useEffect(() => {
    function handleToggle() {
      setOpen((prev) => !prev);
    }
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") setOpen(false);
    }
    window.addEventListener("toggle-cart", handleToggle);
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("toggle-cart", handleToggle);
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, []);

  if (!open) return null;

  const shippingProgress = Math.min(100, (total / FREE_SHIPPING_THRESHOLD) * 100);

  return (
    <div className="fixed inset-0 z-[100]" role="dialog" aria-modal="true" aria-label="Shopping cart">
      {/* Overlay */}
      <div
        className="absolute inset-0 bg-black/40"
        onClick={() => setOpen(false)}
      />

      {/* Drawer */}
      <div className="absolute right-0 top-0 h-full w-full max-w-md bg-[var(--color-bg)] shadow-xl flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[color-mix(in_srgb,var(--color-muted)_20%,transparent)]">
          <h2 className="text-lg font-semibold">Cart</h2>
          <button
            onClick={() => setOpen(false)}
            className="text-[var(--color-muted)] hover:text-[var(--color-text)] transition-colors"
            aria-label="Close cart"
          >
            <svg xmlns="http://www.w3.org/2000/svg" className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Items */}
        <div className="flex-1 overflow-y-auto px-6 py-4">
          {items.length === 0 ? (
            <p className="text-[var(--color-muted)] text-sm text-center mt-10">
              Your cart is empty.
            </p>
          ) : (
            <ul className="space-y-4">
              {items.map((item) => (
                <li key={item.variantId} className="flex gap-4">
                  {/* Item Image Placeholder */}
                  <div className="w-16 h-16 shrink-0 bg-[var(--color-surface)] rounded flex items-center justify-center">
                    <span className="text-[var(--color-muted)] text-[10px]">IMG</span>
                  </div>

                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{item.designName}</p>
                    <p className="text-xs text-[var(--color-muted)]">
                      {item.productType === "long_sleeve" ? "Long Sleeve" : item.productType === "hoodie" ? "Hoodie" : "Tee"} / {item.color} / {item.size}
                    </p>

                    <div className="flex items-center justify-between mt-2">
                      {/* Qty Stepper */}
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => updateQty(item.variantId, item.qty - 1)}
                          className="w-6 h-6 text-xs border border-[color-mix(in_srgb,var(--color-muted)_30%,transparent)] rounded flex items-center justify-center text-[var(--color-muted)] hover:text-[var(--color-text)]"
                          aria-label="Decrease quantity"
                        >
                          -
                        </button>
                        <span className="text-sm w-4 text-center">{item.qty}</span>
                        <button
                          onClick={() => updateQty(item.variantId, item.qty + 1)}
                          className="w-6 h-6 text-xs border border-[color-mix(in_srgb,var(--color-muted)_30%,transparent)] rounded flex items-center justify-center text-[var(--color-muted)] hover:text-[var(--color-text)]"
                          aria-label="Increase quantity"
                        >
                          +
                        </button>
                      </div>

                      <div className="flex items-center gap-3">
                        <span className="text-sm">{formatPrice(item.price * item.qty)}</span>
                        <button
                          onClick={() => removeFromCart(item.variantId)}
                          className="text-[var(--color-muted)] hover:text-[var(--color-text)] transition-colors"
                          aria-label={`Remove ${item.designName}`}
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
                          </svg>
                        </button>
                      </div>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>

        {/* Footer */}
        {items.length > 0 && (
          <div className="border-t border-[color-mix(in_srgb,var(--color-muted)_20%,transparent)] px-6 py-4 space-y-4">
            {/* Free Shipping Progress */}
            <div>
              {freeShippingRemaining > 0 ? (
                <>
                  <p className="text-xs text-[var(--color-muted)] mb-2">
                    {formatPrice(freeShippingRemaining)} away from free shipping
                  </p>
                  <div className="w-full h-1.5 bg-[var(--color-surface)] rounded-full overflow-hidden">
                    <div
                      className="h-full bg-[var(--color-accent)] rounded-full transition-all duration-300"
                      style={{ width: `${shippingProgress}%` }}
                    />
                  </div>
                </>
              ) : (
                <p className="text-xs text-[var(--color-accent)] font-medium">
                  Free Shipping!
                </p>
              )}
            </div>

            {/* Subtotal */}
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Subtotal</span>
              <span className="text-sm font-medium">{formatPrice(total)}</span>
            </div>

            {/* Checkout Button */}
            {checkoutError && (
              <p className="text-red-500 text-xs">{checkoutError}</p>
            )}
            <button
              onClick={async () => {
                setCheckoutLoading(true);
                setCheckoutError("");
                try {
                  const res = await fetch("/.netlify/functions/create-checkout-session", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ items, cartTotal: total }),
                  });
                  const data = await res.json();
                  if (data.url) {
                    window.location.href = data.url;
                  } else {
                    setCheckoutError(data.error || "Checkout failed.");
                    setCheckoutLoading(false);
                  }
                } catch {
                  setCheckoutError("Something went wrong. Please try again.");
                  setCheckoutLoading(false);
                }
              }}
              disabled={checkoutLoading}
              className="w-full py-3 bg-[var(--color-accent)] text-[var(--color-bg)] text-sm font-medium rounded hover:opacity-90 transition-opacity disabled:opacity-50"
            >
              {checkoutLoading ? "Redirecting..." : "Checkout"}
            </button>

            <button
              onClick={() => setOpen(false)}
              className="w-full py-2 text-sm text-[var(--color-muted)] hover:text-[var(--color-text)] transition-colors"
            >
              Continue Shopping
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
