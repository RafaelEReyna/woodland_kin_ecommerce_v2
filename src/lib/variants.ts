import type { ProductType } from "./pricing";

export const PRODUCT_TYPES: ProductType[] = ["tee", "long_sleeve", "hoodie"];

export const COLORS_BY_PRODUCT_TYPE: Record<ProductType, readonly string[]> = {
  tee: ["Black", "Navy", "Forest Green", "Dark Chocolate", "Charcoal"] as const,
  long_sleeve: ["Black", "Navy", "Forest Green", "Military Green"] as const,
  hoodie: ["Black", "Navy", "Forest Green", "Charcoal"] as const,
};

const DESIGN_COLOR_OVERRIDES: Record<string, Partial<Record<ProductType, readonly string[]>>> = {
  "moonridge-both-mountains": {
    hoodie: ["Black", "Navy", "Forest Green", "Charcoal", "Indigo Blue", "Graphite Heather", "Military Green", "Sand"],
  },
  "pine-ridge-sunset": {
    long_sleeve: ["Black", "Navy", "Forest Green", "Military Green", "Sand"],
  },
};

export const SIZES = ["S", "M", "L", "XL", "2XL", "3XL"] as const;

export type Variant = {
  variantId: string;
  designSlug: string;
  productType: ProductType;
  color: string;
  size: string;
};

export function getColorsForProductType(productType: ProductType, designSlug?: string): readonly string[] {
  if (designSlug) {
    const override = DESIGN_COLOR_OVERRIDES[designSlug]?.[productType];
    if (override) return override;
  }
  return COLORS_BY_PRODUCT_TYPE[productType];
}

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
    for (const color of getColorsForProductType(productType, designSlug)) {
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
