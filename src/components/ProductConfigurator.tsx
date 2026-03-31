import { useState, useEffect } from "react";
import ProductTypeSelector from "./ProductTypeSelector";
import ColorSelector from "./ColorSelector";
import SizeSelector from "./SizeSelector";
import { getPrice, formatPrice } from "../lib/pricing";
import { generateVariantId, getColorsForProductType } from "../lib/variants";
import { addToCart } from "../stores/cart";
import type { ProductType } from "../lib/pricing";

interface Props {
  designSlug: string;
  designName: string;
  mockupImages: Record<string, string>;
  fallbackImage: string;
}

export default function ProductConfigurator({ designSlug, designName, mockupImages, fallbackImage }: Props) {
  const [productType, setProductType] = useState<ProductType>("tee");
  const [color, setColor] = useState("Black");
  const [size, setSize] = useState("M");
  const [feedback, setFeedback] = useState("");

  const availableColors = getColorsForProductType(productType, designSlug);
  const price = getPrice(productType);
  const variantId = generateVariantId(designSlug, productType, color, size);

  const productTypeLabels: Record<ProductType, string> = {
    tee: "Tee",
    long_sleeve: "Long Sleeve",
    hoodie: "Hoodie",
  };
  const displayName = `${designName} ${productTypeLabels[productType]}`;

  const normalizedColor = color.toLowerCase().replace(/\s+/g, "-");
  const imageKey = `${designSlug}/${productType}-${normalizedColor}`;
  const currentImage = mockupImages[imageKey] || fallbackImage;

  useEffect(() => {
    window.dispatchEvent(
      new CustomEvent("product-image-change", { detail: { src: currentImage } })
    );
  }, [currentImage]);

  function handleProductTypeChange(newType: ProductType) {
    setProductType(newType);
    const newColors = getColorsForProductType(newType, designSlug);
    if (!newColors.includes(color)) {
      setColor(newColors[0]);
    }
  }

  function handleAddToCart() {
    addToCart({ variantId, designName, productType, color, size, price });
    window.dispatchEvent(new CustomEvent("toggle-cart"));
    setFeedback("Added!");
    setTimeout(() => setFeedback(""), 1000);
  }

  return (
    <div>
      <h1 className="text-2xl md:text-3xl font-bold">{displayName}</h1>
      <p className="mt-2 text-xl text-[var(--color-text-muted)]">{formatPrice(price)}</p>

      <div className="mt-8 space-y-6">
        <ProductTypeSelector selectedType={productType} onChange={handleProductTypeChange} />
        <ColorSelector colors={availableColors} selectedColor={color} onChange={setColor} />
        <SizeSelector selectedSize={size} onChange={setSize} />
      </div>

      <button
        onClick={handleAddToCart}
        className="mt-8 w-full py-3 bg-[var(--color-accent)] text-[var(--color-bg)] text-sm font-medium rounded hover:opacity-90 transition-opacity"
      >
        {feedback || "Add to Cart"}
      </button>
    </div>
  );
}
