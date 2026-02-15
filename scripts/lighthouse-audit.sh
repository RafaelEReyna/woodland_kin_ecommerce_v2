#!/usr/bin/env bash
# Woodland Kin — Lighthouse Audit
# Usage: ./scripts/lighthouse-audit.sh
#
# Prerequisites:
#   - lighthouse: npm install -g lighthouse
#   - Google Chrome installed
#   - netlify dev running on localhost:8888 (or specify BASE_URL)

set -e

BASE_URL="${BASE_URL:-http://localhost:8888}"
REPORT_DIR="reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Pages to audit
PAGES=(
  "/|home"
  "/shop|shop"
  "/shop/bear-valley-crest|design-detail"
)

echo "========================================="
echo " Woodland Kin — Lighthouse Audit"
echo " Target: $BASE_URL"
echo " Reports: $REPORT_DIR/"
echo "========================================="
echo ""

# ------------------------------------------
# Prerequisites check
# ------------------------------------------
if ! command -v lighthouse &>/dev/null; then
  echo "ERROR: Lighthouse CLI not found."
  echo ""
  echo "Install with:"
  echo "  npm install -g lighthouse"
  exit 1
fi

# Check Chrome is available
CHROME_PATH=""
if [[ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
  CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
elif command -v google-chrome &>/dev/null; then
  CHROME_PATH=$(command -v google-chrome)
elif command -v chromium &>/dev/null; then
  CHROME_PATH=$(command -v chromium)
fi

if [[ -z "$CHROME_PATH" ]]; then
  echo "WARNING: Google Chrome not found at expected paths."
  echo "Lighthouse will attempt to find it automatically."
  echo ""
fi

echo -n "Checking site availability: "
if curl -s --max-time 5 "$BASE_URL" > /dev/null; then
  echo "OK"
else
  echo "FAILED"
  echo "Start the dev server with: netlify dev"
  exit 1
fi
echo ""

# Create reports directory
mkdir -p "$REPORT_DIR"

# ------------------------------------------
# Run audits
# ------------------------------------------
declare -A SCORES

for PAGE_ENTRY in "${PAGES[@]}"; do
  IFS="|" read -r PAGE_PATH PAGE_NAME <<< "$PAGE_ENTRY"
  URL="${BASE_URL}${PAGE_PATH}"
  REPORT_FILE="${REPORT_DIR}/lighthouse-${PAGE_NAME}-${TIMESTAMP}.html"
  JSON_FILE="${REPORT_DIR}/lighthouse-${PAGE_NAME}-${TIMESTAMP}.json"

  echo "--- Auditing: ${PAGE_NAME} (${URL}) ---"

  CHROME_FLAGS="--headless --no-sandbox"
  if [[ -n "$CHROME_PATH" ]]; then
    CHROME_FLAGS="$CHROME_FLAGS"
    export CHROME_PATH
  fi

  lighthouse "$URL" \
    --output html,json \
    --output-path "${REPORT_DIR}/lighthouse-${PAGE_NAME}-${TIMESTAMP}" \
    --chrome-flags="$CHROME_FLAGS" \
    --quiet \
    2>/dev/null || {
      echo "[WARN] Lighthouse failed for ${PAGE_NAME}. Skipping."
      echo ""
      continue
    }

  # Extract scores from JSON report
  if [[ -f "$JSON_FILE" ]]; then
    PERF=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(int(d['categories']['performance']['score']*100))" 2>/dev/null || echo "?")
    A11Y=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(int(d['categories']['accessibility']['score']*100))" 2>/dev/null || echo "?")
    BP=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(int(d['categories']['best-practices']['score']*100))" 2>/dev/null || echo "?")
    SEO=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(int(d['categories']['seo']['score']*100))" 2>/dev/null || echo "?")

    SCORES["${PAGE_NAME}_perf"]="$PERF"
    SCORES["${PAGE_NAME}_a11y"]="$A11Y"
    SCORES["${PAGE_NAME}_bp"]="$BP"
    SCORES["${PAGE_NAME}_seo"]="$SEO"

    echo "  Performance:    ${PERF}"
    echo "  Accessibility:  ${A11Y}"
    echo "  Best Practices: ${BP}"
    echo "  SEO:            ${SEO}"
    echo "  Report: ${REPORT_FILE}"
  fi
  echo ""
done

# ------------------------------------------
# Summary
# ------------------------------------------
echo "========================================="
echo " LIGHTHOUSE SCORE SUMMARY"
echo "========================================="
echo ""
printf "  %-20s %6s %6s %6s %6s\n" "Page" "Perf" "A11y" "BP" "SEO"
printf "  %-20s %6s %6s %6s %6s\n" "----" "----" "----" "----" "----"

for PAGE_ENTRY in "${PAGES[@]}"; do
  IFS="|" read -r _ PAGE_NAME <<< "$PAGE_ENTRY"
  PERF="${SCORES["${PAGE_NAME}_perf"]:-N/A}"
  A11Y="${SCORES["${PAGE_NAME}_a11y"]:-N/A}"
  BP="${SCORES["${PAGE_NAME}_bp"]:-N/A}"
  SEO="${SCORES["${PAGE_NAME}_seo"]:-N/A}"
  printf "  %-20s %6s %6s %6s %6s\n" "$PAGE_NAME" "$PERF" "$A11Y" "$BP" "$SEO"
done

echo ""
echo " Target: All scores >= 90"
echo ""

# Check targets
PASS=true
for PAGE_ENTRY in "${PAGES[@]}"; do
  IFS="|" read -r _ PAGE_NAME <<< "$PAGE_ENTRY"
  for CATEGORY in perf a11y; do
    SCORE="${SCORES["${PAGE_NAME}_${CATEGORY}"]:-0}"
    if [[ "$SCORE" != "?" && "$SCORE" -lt 90 ]] 2>/dev/null; then
      echo " [WARN] ${PAGE_NAME} ${CATEGORY}: ${SCORE} (below 90)"
      PASS=false
    fi
  done
done

echo ""
if $PASS; then
  echo " [PASS] All target scores met."
else
  echo " [WARN] Some scores below target. Review reports for details."
fi

echo ""
echo " Full reports saved to: $REPORT_DIR/"
echo "========================================="
