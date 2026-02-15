/**
 * Maps Woodland Kin variant IDs to Printful sync variant IDs.
 *
 * IMPORTANT: These are placeholder IDs. Before launch, replace each value
 * with the actual Printful sync variant ID from your Printful dashboard.
 * You can find these IDs in Printful > Stores > Products > Sync Variants.
 */
export const PRINTFUL_VARIANT_MAP: Record<string, number> = {
  // Bear Valley Crest — Tee
  "bear-valley-crest-tee-charcoal-xs": 100001,
  "bear-valley-crest-tee-charcoal-s": 100002,
  "bear-valley-crest-tee-charcoal-m": 100003,
  "bear-valley-crest-tee-charcoal-l": 100004,
  "bear-valley-crest-tee-charcoal-xl": 100005,
  "bear-valley-crest-tee-charcoal-2xl": 100006,
  "bear-valley-crest-tee-charcoal-3xl": 100007,
  // Add all remaining variant mappings before launch
};

export function getPrintfulVariantId(variantId: string): number | null {
  return PRINTFUL_VARIANT_MAP[variantId] ?? null;
}
