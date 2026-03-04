const COLOR_MAP: Record<string, string> = {
  Black: "#1A1A1A",
  Navy: "#1F2937",
  "Forest Green": "#4A7C59",
  "Dark Chocolate": "#3E2723",
  Charcoal: "#4A4A4A",
  "Military Green": "#4B5320",
};

interface Props {
  colors: readonly string[];
  selectedColor: string;
  onChange: (color: string) => void;
}

export default function ColorSelector({ colors, selectedColor, onChange }: Props) {

  return (
    <div>
      <h3 className="text-sm font-medium mb-3">
        Color — <span className="text-[var(--color-muted)]">{selectedColor}</span>
      </h3>
      <div className="flex gap-3">
        {colors.map((color) => {
          const isSelected = color === selectedColor;
          return (
            <button
              key={color}
              onClick={() => onChange(color)}
              aria-label={color}
              title={color}
              className={`w-8 h-8 rounded-full transition-shadow ${
                isSelected
                  ? "ring-2 ring-[var(--color-accent)] ring-offset-2"
                  : "hover:ring-2 hover:ring-[var(--color-muted)] hover:ring-offset-1"
              }`}
              style={{
                backgroundColor: COLOR_MAP[color] || "#888",
                ringOffsetColor: "var(--color-bg)",
              }}
            />
          );
        })}
      </div>
    </div>
  );
}
