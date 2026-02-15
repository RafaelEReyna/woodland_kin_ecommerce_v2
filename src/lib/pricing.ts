export type ProductType = "tee" | "long_sleeve" | "hoodie";

export const PRICES: Record<ProductType, number> = {
  tee: 2500,
  long_sleeve: 4000,
  hoodie: 5800,
};

export function getPrice(type: ProductType): number {
  return PRICES[type];
}

export function formatPrice(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

export const FREE_SHIPPING_THRESHOLD = 10000;
