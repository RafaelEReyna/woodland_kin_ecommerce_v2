import { SIZES } from "../lib/variants";

interface Props {
  selectedSize: string;
  onChange: (size: string) => void;
}

export default function SizeSelector({ selectedSize, onChange }: Props) {
  return (
    <div>
      <h3 className="text-sm font-medium mb-3">Size</h3>
      <div className="flex flex-wrap gap-2">
        {SIZES.map((size) => {
          const isSelected = size === selectedSize;
          return (
            <button
              key={size}
              onClick={() => onChange(size)}
              className={`px-3 py-1.5 text-sm rounded border transition-colors ${
                isSelected
                  ? "border-[var(--color-accent)] bg-[var(--color-accent)] text-[var(--color-bg)]"
                  : "border-[color-mix(in_srgb,var(--color-muted)_30%,transparent)] text-[var(--color-muted)] hover:border-[var(--color-muted)]"
              }`}
            >
              {size}
            </button>
          );
        })}
      </div>
    </div>
  );
}
