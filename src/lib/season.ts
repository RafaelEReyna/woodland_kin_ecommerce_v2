export type Theme = "light" | "dark";

/**
 * Returns the seasonal theme based on the current date.
 * Light theme: April (4) through September (9)
 * Dark theme: October (10) through March (3)
 */
export function getTheme(): Theme {
  const month = new Date().getMonth() + 1; // getMonth() is 0-indexed
  return month >= 4 && month <= 9 ? "light" : "dark";
}
