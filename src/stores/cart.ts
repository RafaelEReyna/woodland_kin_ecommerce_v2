import { atom, computed } from "nanostores";
import type { ProductType } from "../lib/pricing";
import { FREE_SHIPPING_THRESHOLD } from "../lib/pricing";

export interface CartItem {
  variantId: string;
  designName: string;
  productType: ProductType;
  color: string;
  size: string;
  price: number;
  qty: number;
}

const STORAGE_KEY = "woodland-kin-cart";

function loadCart(): CartItem[] {
  if (typeof window === "undefined") return [];
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    return saved ? JSON.parse(saved) : [];
  } catch {
    return [];
  }
}

function saveCart(items: CartItem[]) {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
  } catch {
    // localStorage full or unavailable
  }
}

export const $cart = atom<CartItem[]>(loadCart());

$cart.listen((items) => saveCart(items));

export const $cartCount = computed($cart, (items) =>
  items.reduce((sum, item) => sum + item.qty, 0)
);

export const $cartTotal = computed($cart, (items) =>
  items.reduce((sum, item) => sum + item.price * item.qty, 0)
);

export const $freeShippingRemaining = computed($cartTotal, (total) =>
  Math.max(0, FREE_SHIPPING_THRESHOLD - total)
);

export function addToCart(item: Omit<CartItem, "qty">) {
  const items = $cart.get();
  const existing = items.find((i) => i.variantId === item.variantId);
  if (existing) {
    $cart.set(
      items.map((i) =>
        i.variantId === item.variantId ? { ...i, qty: i.qty + 1 } : i
      )
    );
  } else {
    $cart.set([...items, { ...item, qty: 1 }]);
  }
}

export function removeFromCart(variantId: string) {
  $cart.set($cart.get().filter((i) => i.variantId !== variantId));
}

export function updateQty(variantId: string, qty: number) {
  if (qty <= 0) {
    removeFromCart(variantId);
    return;
  }
  $cart.set(
    $cart.get().map((i) => (i.variantId === variantId ? { ...i, qty } : i))
  );
}

export function clearCart() {
  $cart.set([]);
}
