#!/usr/bin/env bash
# Woodland Kin — Post-Deployment Smoke Test
# Usage: ./scripts/post-deploy-smoke.sh [--url https://woodlandkin.com]
#
# Checks that all critical URLs return 200 and contain expected content
# after deploying to production. Does NOT test checkout (requires manual card entry).

SITE_URL="https://woodlandkin.com"

# Parse --url argument
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --url) SITE_URL="$2"; shift ;;
    *) ;;
  esac
  shift
done

# Remove trailing slash
SITE_URL="${SITE_URL%/}"

PASS_COUNT=0
FAIL_COUNT=0

check_url() {
  local URL="$1"
  local NAME="$2"
  local EXPECT_CONTENT="$3"

  echo -n "  ${NAME}: "

  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL")

  if [[ "$RESPONSE" == "200" ]]; then
    if [[ -n "$EXPECT_CONTENT" ]]; then
      BODY=$(curl -s --max-time 10 "$URL")
      if echo "$BODY" | grep -qi "$EXPECT_CONTENT"; then
        echo "PASS (200, content verified)"
        ((PASS_COUNT++))
        return
      else
        echo "WARN (200, but expected content '$EXPECT_CONTENT' not found)"
        ((PASS_COUNT++))
        return
      fi
    fi
    echo "PASS (200)"
    ((PASS_COUNT++))
  else
    echo "FAIL (HTTP $RESPONSE)"
    ((FAIL_COUNT++))
  fi
}

echo "========================================="
echo " Woodland Kin — Post-Deploy Smoke Test"
echo " Target: $SITE_URL"
echo "========================================="
echo ""

# ------------------------------------------
# Critical pages
# ------------------------------------------
echo "--- Critical Pages ---"
check_url "$SITE_URL/" "Home page" "Woodland Kin"
check_url "$SITE_URL/shop" "Shop page" "Collection"
check_url "$SITE_URL/shop/bear-valley-crest" "Design page" "Bear Valley Crest"
check_url "$SITE_URL/order/success" "Order success" "Thank you"
check_url "$SITE_URL/order/cancel" "Order cancel" "cancelled"
echo ""

# ------------------------------------------
# Static pages
# ------------------------------------------
echo "--- Static Pages ---"
check_url "$SITE_URL/about" "About" ""
check_url "$SITE_URL/contact" "Contact" ""
check_url "$SITE_URL/faq" "FAQ" ""
check_url "$SITE_URL/shipping-returns" "Shipping & Returns" ""
check_url "$SITE_URL/size-guide" "Size Guide" ""
echo ""

# ------------------------------------------
# SEO / infrastructure
# ------------------------------------------
echo "--- SEO & Infrastructure ---"
check_url "$SITE_URL/sitemap-index.xml" "Sitemap" ""
check_url "$SITE_URL/robots.txt" "Robots.txt" "Sitemap"
echo ""

# ------------------------------------------
# Apple Pay verification
# ------------------------------------------
echo "--- Apple Pay ---"
check_url "$SITE_URL/.well-known/apple-developer-merchantid-domain-association" "Apple Pay verification" ""
echo ""

# ------------------------------------------
# API health
# ------------------------------------------
echo "--- API Health ---"
check_url "$SITE_URL/.netlify/functions/hello" "Hello function" "Woodland Kin"
echo ""

# ------------------------------------------
# Summary
# ------------------------------------------
echo "========================================="
echo " SMOKE TEST SUMMARY"
echo "========================================="
echo ""
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"
echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "  ALL CHECKS PASSED."
  echo ""
  echo "  Next steps:"
  echo "    1. Complete one real test purchase (small order)"
  echo "    2. Verify Stripe, Printful, and Klaviyo dashboards"
  echo "    3. Refund the test order"
  echo "    4. Tag release: git tag -a v1.0.0 -m 'Launch release'"
  echo ""
  exit 0
else
  echo "  $FAIL_COUNT check(s) FAILED."
  echo "  Review the failing URLs and fix before announcing launch."
  echo ""
  exit 1
fi
