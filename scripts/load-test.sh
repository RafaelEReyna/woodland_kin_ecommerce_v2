#!/usr/bin/env bash
# Woodland Kin — Load Test (Progressive Concurrency)
# Usage: ./scripts/load-test.sh
#
# Prerequisites:
#   - hey: brew install hey (or go install github.com/rakyll/hey@latest)
#   - netlify dev running on localhost:8888
#   - .env with STRIPE_SECRET_KEY (sk_test_)

set -e

BASE_URL="${BASE_URL:-http://localhost:8888}"
ENDPOINT="$BASE_URL/.netlify/functions/create-checkout-session"
HELLO_ENDPOINT="$BASE_URL/.netlify/functions/hello"

# Single item payload (under $100, standard shipping path)
SINGLE_ITEM='{"items":[{"variantId":"bear-valley-crest-tee-charcoal-m","designName":"Bear Valley Crest","productType":"tee","color":"Charcoal","size":"M","price":2500,"qty":1}],"cartTotal":2500}'

# Multi-item payload (over $100, free shipping path)
MULTI_ITEM='{"items":[{"variantId":"bear-valley-crest-tee-charcoal-m","designName":"Bear Valley Crest","productType":"tee","color":"Charcoal","size":"M","price":2500,"qty":2},{"variantId":"pine-ridge-sunset-hoodie-forest-green-l","designName":"Pine Ridge Sunset","productType":"hoodie","color":"Forest Green","size":"L","price":5800,"qty":1}],"cartTotal":10800}'

echo "========================================="
echo " Woodland Kin — Load Test"
echo " Target: $ENDPOINT"
echo "========================================="
echo ""

# ------------------------------------------
# Prerequisites check
# ------------------------------------------
if ! command -v hey &>/dev/null; then
  echo "ERROR: 'hey' load testing tool not found."
  echo ""
  echo "Install with one of:"
  echo "  brew install hey"
  echo "  go install github.com/rakyll/hey@latest"
  exit 1
fi

echo -n "Checking netlify dev: "
if curl -s --max-time 3 "$HELLO_ENDPOINT" | grep -q "Woodland Kin"; then
  echo "RUNNING"
else
  echo "NOT FOUND"
  echo "Start with: netlify dev"
  exit 1
fi
echo ""

# ------------------------------------------
# Tier 1: Warm-up (10 requests, 2 concurrent)
# ------------------------------------------
echo "========================================="
echo " Tier 1: Warm-up — 10 requests, 2 concurrent"
echo "========================================="
echo ""

hey -n 10 -c 2 -m POST \
  -H "Content-Type: application/json" \
  -d "$SINGLE_ITEM" \
  "$ENDPOINT"

echo ""
echo "--- Tier 1 complete. Review results above. ---"
echo ""
if [ -t 0 ]; then
  read -p "Continue to Tier 2? (Enter to continue, Ctrl+C to stop) "
fi
echo ""

# ------------------------------------------
# Tier 2: Moderate (50 requests, 10 concurrent)
# ------------------------------------------
echo "========================================="
echo " Tier 2: Moderate — 50 requests, 10 concurrent"
echo "========================================="
echo ""

hey -n 50 -c 10 -m POST \
  -H "Content-Type: application/json" \
  -d "$SINGLE_ITEM" \
  "$ENDPOINT"

echo ""
echo "--- Tier 2 complete. Review results above. ---"
echo ""

# Check for errors in Tier 2 output
echo "Target check:"
echo "  - p99 latency < 3s"
echo "  - 0% error rate (all status 200)"
echo ""
if [ -t 0 ]; then
  read -p "Continue to Tier 3 (target load)? (Enter to continue, Ctrl+C to stop) "
fi
echo ""

# ------------------------------------------
# Tier 3: Target (200 requests, 50 concurrent)
# ------------------------------------------
echo "========================================="
echo " Tier 3: TARGET — 200 requests, 50 concurrent"
echo "========================================="
echo ""

hey -n 200 -c 50 -m POST \
  -H "Content-Type: application/json" \
  -d "$SINGLE_ITEM" \
  "$ENDPOINT"

echo ""
echo "--- Tier 3 (single item) complete. ---"
echo ""
echo "Target metrics:"
echo "  - p99 latency < 3s"
echo "  - 0% error rate"
echo ""

# ------------------------------------------
# Tier 3b: Multi-item cart (200 requests, 50 concurrent)
# ------------------------------------------
echo "========================================="
echo " Tier 3b: Multi-item cart — 200 requests, 50 concurrent"
echo "========================================="
echo ""

hey -n 200 -c 50 -m POST \
  -H "Content-Type: application/json" \
  -d "$MULTI_ITEM" \
  "$ENDPOINT"

echo ""
echo "--- Tier 3b (multi-item) complete. ---"
echo ""

# ------------------------------------------
# Summary
# ------------------------------------------
echo "========================================="
echo " Load Test Complete"
echo "========================================="
echo ""
echo " Target metrics (Tier 3 and 3b):"
echo "   [  ] p99 latency < 3 seconds"
echo "   [  ] Error rate: 0%"
echo "   [  ] All 200 responses returned status 200"
echo ""
echo " Stripe rate limit note:"
echo "   If you see HTTP 429 errors, that's Stripe's test-mode"
echo "   rate limit (25 req/sec) — not a code issue. In production,"
echo "   Stripe allows higher throughput. To work around in testing,"
echo "   reduce concurrency: hey -n 100 -c 20 ..."
echo ""
echo "========================================="
