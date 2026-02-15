/**
 * Woodland Kin — Printful Variant Mapping Verification
 *
 * Checks how many product variants are mapped to Printful sync variant IDs.
 * Run with: npx tsx scripts/verify-variant-map.ts
 */

import { PRINTFUL_VARIANT_MAP } from "../src/data/printful-map";
import { generateAllVariants } from "../src/lib/variants";

const DESIGN_SLUGS = [
  "bear-valley-crest",
  "pine-ridge-sunset",
  "woodland-original",
];

const PLACEHOLDER_RANGE_MIN = 100000;
const PLACEHOLDER_RANGE_MAX = 199999;

console.log("=========================================");
console.log(" Woodland Kin — Variant Mapping Report");
console.log("=========================================");
console.log("");

let totalVariants = 0;
let mappedVariants = 0;
let placeholderVariants = 0;
let unmappedVariants = 0;
const unmappedByDesign: Record<string, string[]> = {};

for (const slug of DESIGN_SLUGS) {
  const variants = generateAllVariants(slug);
  const designUnmapped: string[] = [];
  let designMapped = 0;
  let designPlaceholder = 0;

  for (const variant of variants) {
    totalVariants++;
    const printfulId = PRINTFUL_VARIANT_MAP[variant.variantId];

    if (printfulId === undefined || printfulId === null) {
      unmappedVariants++;
      designUnmapped.push(variant.variantId);
    } else if (
      printfulId >= PLACEHOLDER_RANGE_MIN &&
      printfulId <= PLACEHOLDER_RANGE_MAX
    ) {
      placeholderVariants++;
      designPlaceholder++;
    } else {
      mappedVariants++;
      designMapped++;
    }
  }

  const totalDesignMapped = designMapped + designPlaceholder;
  const status =
    designUnmapped.length === 0 && designPlaceholder === 0
      ? "COMPLETE"
      : `${totalDesignMapped}/${variants.length} mapped`;

  console.log(
    `  ${slug}: ${status}${designPlaceholder > 0 ? ` (${designPlaceholder} placeholder)` : ""}`
  );

  if (designUnmapped.length > 0) {
    unmappedByDesign[slug] = designUnmapped;
  }
}

console.log("");
console.log("--------- Summary ---------");
console.log(`  Total variants:     ${totalVariants}`);
console.log(
  `  Mapped (real IDs):  ${mappedVariants} (${((mappedVariants / totalVariants) * 100).toFixed(1)}%)`
);
console.log(
  `  Placeholder IDs:    ${placeholderVariants} (${((placeholderVariants / totalVariants) * 100).toFixed(1)}%)`
);
console.log(
  `  Unmapped:           ${unmappedVariants} (${((unmappedVariants / totalVariants) * 100).toFixed(1)}%)`
);
console.log("");

if (placeholderVariants > 0) {
  console.log(
    `WARNING: ${placeholderVariants} variants use placeholder IDs (${PLACEHOLDER_RANGE_MIN}-range).`
  );
  console.log(
    "  These will fail at Printful order time. Replace with real sync variant IDs."
  );
  console.log("");
}

if (unmappedVariants > 0) {
  console.log(
    `WARNING: ${unmappedVariants} variants have no Printful mapping at all.`
  );
  console.log(
    "  Orders containing these variants will fail silently."
  );
  console.log("");

  console.log("--------- Unmapped Variants by Design ---------");
  for (const [slug, variants] of Object.entries(unmappedByDesign)) {
    console.log(`\n  ${slug} (${variants.length} unmapped):`);
    // Show first 5, then summarize
    const shown = variants.slice(0, 5);
    for (const v of shown) {
      console.log(`    - ${v}`);
    }
    if (variants.length > 5) {
      console.log(`    ... and ${variants.length - 5} more`);
    }
  }
  console.log("");
}

if (unmappedVariants === 0 && placeholderVariants === 0) {
  console.log("ALL VARIANTS MAPPED with real Printful IDs. Ready for launch!");
} else {
  console.log("ACTION REQUIRED: Populate src/data/printful-map.ts with real");
  console.log("Printful sync variant IDs before launch.");
  console.log("");
  console.log("To find IDs: Printful Dashboard → Products → Sync Products");
  console.log("→ select product → each variant shows its sync_variant_id.");
}

console.log("");
console.log("=========================================");
