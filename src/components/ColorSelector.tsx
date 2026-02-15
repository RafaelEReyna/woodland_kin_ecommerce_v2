const COLOR_MAP: Record<string, string> = {
  Charcoal: "#4A4A4A",
  "Forest Green": "#4A7C59",
  Sand: "#C9B99A",
  "Faded Navy": "#5B6E82",
};

interface Props {
  selectedColor: string;
  onChange: (color: string) => void;
}

export default function ColorSelector({ selectedColor, onChange }: Props) {
  const colors = Object.keys(COLOR_MAP);

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
                backgroundColor: COLOR_MAP[color],
                ringOffsetColor: "var(--color-bg)",
              }}
            />
          );
        })}
      </div>
    </div>
  );
}
