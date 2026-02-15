import type { ProductType } from "./pricing";

export const PRODUCT_TYPES: ProductType[] = ["tee", "long_sleeve", "hoodie"];

export const COLORS = ["Charcoal", "Forest Green", "Sand", "Faded Navy"] as const;

export const SIZES = ["XS", "S", "M", "L", "XL", "2XL", "3XL"] as const;

export type Variant = {
  variantId: string;
  designSlug: string;
  productType: ProductType;
  color: string;
  size: string;
};

export function generateVariantId(
  designSlug: string,
  productType: ProductType,
  color: string,
  size: string
): string {
  const normalizedColor = color.toLowerCase().replace(/\s+/g, "-");
  const normalizedSize = size.toLowerCase();
  return `${designSlug}-${productType}-${normalizedColor}-${normalizedSize}`;
}

export function generateAllVariants(designSlug: string): Variant[] {
  const variants: Variant[] = [];
  for (const productType of PRODUCT_TYPES) {
    for (const color of COLORS) {
      for (const size of SIZES) {
        variants.push({
          variantId: generateVariantId(designSlug, productType, color, size),
          designSlug,
          productType,
          color,
          size,
        });
      }
    }
  }
  return variants;
}
