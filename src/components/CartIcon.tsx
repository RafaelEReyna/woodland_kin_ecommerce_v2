import { useStore } from "@nanostores/react";
import { $cartCount } from "../stores/cart";

export default function CartIcon() {
  const count = useStore($cartCount);

  function handleClick() {
    window.dispatchEvent(new CustomEvent("toggle-cart"));
  }

  return (
    <button
      onClick={handleClick}
      className="relative text-[var(--color-muted)] hover:text-[var(--color-text)] transition-colors"
      aria-label={`Cart: ${count} items`}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        className="w-5 h-5"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        strokeWidth={1.5}
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M15.75 10.5V6a3.75 3.75 0 1 0-7.5 0v4.5m11.356-1.993 1.263 12c.07.665-.45 1.243-1.119 1.243H4.25a1.125 1.125 0 0 1-1.12-1.243l1.264-12A1.125 1.125 0 0 1 5.513 7.5h12.974c.576 0 1.059.435 1.119 1.007ZM8.625 10.5a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm7.5 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z"
        />
      </svg>
      {count > 0 && (
        <span className="absolute -top-1.5 -right-1.5 w-4 h-4 text-[10px] font-bold leading-4 text-center rounded-full bg-[var(--color-accent)] text-[var(--color-bg)]">
          {count}
        </span>
      )}
    </button>
  );
}
