import { PRICES, formatPrice } from "../lib/pricing";
import type { ProductType } from "../lib/pricing";

const PRODUCT_TYPE_LABELS: Record<ProductType, string> = {
  tee: "Tee",
  long_sleeve: "Long Sleeve",
  hoodie: "Hoodie",
};

interface Props {
  selectedType: ProductType;
  onChange: (type: ProductType) => void;
}

export default function ProductTypeSelector({ selectedType, onChange }: Props) {
  const types: ProductType[] = ["tee", "long_sleeve", "hoodie"];

  return (
    <div>
      <h3 className="text-sm font-medium mb-3">Product Type</h3>
      <div className="flex flex-wrap gap-3">
        {types.map((type) => {
          const isSelected = type === selectedType;
          return (
            <button
              key={type}
              onClick={() => onChange(type)}
              className={`px-4 py-2 text-sm rounded border transition-colors ${
                isSelected
                  ? "border-[var(--color-accent)] bg-[var(--color-accent)] text-[var(--color-bg)]"
                  : "border-[color-mix(in_srgb,var(--color-muted)_30%,transparent)] text-[var(--color-muted)] hover:border-[var(--color-muted)]"
              }`}
            >
              {PRODUCT_TYPE_LABELS[type]} — {formatPrice(PRICES[type])}
            </button>
          );
        })}
      </div>
    </div>
  );
}
