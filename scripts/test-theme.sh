#!/usr/bin/env bash
# Woodland Kin — Seasonal Theme Simulation Test
# Usage:
#   ./scripts/test-theme.sh --theme light    # Force light theme and build
#   ./scripts/test-theme.sh --theme dark     # Force dark theme and build
#   ./scripts/test-theme.sh --revert         # Restore original season.ts
#
# WARNING: Always revert before committing or deploying!

set -e

SEASON_FILE="src/lib/season.ts"

ORIGINAL_CONTENT='export type Theme = "light" | "dark";

/**
 * Returns the seasonal theme based on the current date.
 * Light theme: April (4) through September (9)
 * Dark theme: October (10) through March (3)
 */
export function getTheme(): Theme {
  const month = new Date().getMonth() + 1; // getMonth() is 0-indexed
  return month >= 4 && month <= 9 ? "light" : "dark";
}'

force_theme() {
  local theme="$1"
  cat > "$SEASON_FILE" << EOF
export type Theme = "light" | "dark";

/**
 * TESTING OVERRIDE — forced to "${theme}" theme.
 * Revert with: ./scripts/test-theme.sh --revert
 */
export function getTheme(): Theme {
  return "${theme}";
}
EOF
  echo "[OVERRIDE] season.ts forced to \"${theme}\" theme."
}

revert_theme() {
  cat > "$SEASON_FILE" << 'EOF'
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
EOF
  echo "[REVERTED] season.ts restored to production date logic."
}

echo "========================================="
echo " Woodland Kin — Theme Simulation Test"
echo "========================================="
echo ""

if [[ "$1" == "--revert" ]]; then
  revert_theme
  echo ""
  echo "--- Verifying build after revert ---"
  npx astro build
  echo ""
  echo "[PASS] Build succeeded with production theme logic."
  exit 0
fi

if [[ "$1" == "--theme" && -n "$2" ]]; then
  THEME="$2"

  if [[ "$THEME" != "light" && "$THEME" != "dark" ]]; then
    echo "ERROR: Theme must be 'light' or 'dark'."
    echo "Usage: ./scripts/test-theme.sh --theme light"
    exit 1
  fi

  force_theme "$THEME"
  echo ""

  echo "--- Building with forced ${THEME} theme ---"
  if npx astro build; then
    echo ""
    echo "[PASS] Build succeeded with \"${THEME}\" theme."
    echo ""
    echo "Next steps:"
    echo "  1. Run 'npx astro preview' or 'netlify dev' to view the site"
    echo "  2. Check all pages for correct theme rendering:"
    if [[ "$THEME" == "light" ]]; then
      echo "     - Background: sand (#F5F0E8)"
      echo "     - Text: dark charcoal (#2C2C2C)"
      echo "     - Accent: lilac (#B8A9C9)"
      echo "     - Surface: white (#FFFFFF)"
      echo "     - Muted: warm gray (#8C8272)"
    else
      echo "     - Background: charcoal (#2C2C2C)"
      echo "     - Text: sand (#F5F0E8)"
      echo "     - Accent: forest green (#4A7C59)"
      echo "     - Surface: dark (#3A3A3A)"
      echo "     - Muted: cool gray (#A09888)"
    fi
    echo ""
    echo "  3. Verify cart drawer, configurator, and email capture render correctly"
    echo "  4. When done: ./scripts/test-theme.sh --revert"
    echo ""
    echo "WARNING: Do NOT commit or deploy with a forced theme override!"
  else
    echo ""
    echo "[FAIL] Build failed with \"${THEME}\" theme."
    echo "Reverting to production logic..."
    revert_theme
    exit 1
  fi
  exit 0
fi

echo "Usage:"
echo "  ./scripts/test-theme.sh --theme light    Force light theme"
echo "  ./scripts/test-theme.sh --theme dark     Force dark theme"
echo "  ./scripts/test-theme.sh --revert         Restore production logic"
exit 1
