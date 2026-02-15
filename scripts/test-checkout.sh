#!/usr/bin/env bash
# Woodland Kin — Stripe Checkout Test Script
# Usage: ./scripts/test-checkout.sh
# Requires: netlify dev running on localhost:8888

BASE_URL="${BASE_URL:-http://localhost:8888}"
ENDPOINT="$BASE_URL/.netlify/functions/create-checkout-session"

echo "========================================="
echo " Woodland Kin — Checkout Tests"
echo " Target: $ENDPOINT"
echo "========================================="
echo ""

# ------------------------------------------
# Test 1: Single item (under $100 — standard shipping)
# ------------------------------------------
echo "--- Test 1: Single Tee ($25.00) — Standard Shipping ---"
curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "variantId": "bear-valley-crest-tee-charcoal-m",
        "designName": "Bear Valley Crest",
        "productType": "tee",
        "color": "Charcoal",
        "size": "M",
        "price": 2500,
        "qty": 1
      }
    ],
    "cartTotal": 2500
  }' | python3 -m json.tool 2>/dev/null || echo "(raw response above)"
echo ""

# ------------------------------------------
# Test 2: Multiple items (under $100 — standard shipping)
# ------------------------------------------
echo "--- Test 2: Tee + Long Sleeve ($65.00) — Standard Shipping ---"
curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "variantId": "bear-valley-crest-tee-charcoal-m",
        "designName": "Bear Valley Crest",
        "productType": "tee",
        "color": "Charcoal",
        "size": "M",
        "price": 2500,
        "qty": 1
      },
      {
        "variantId": "pine-ridge-sunset-long_sleeve-sand-l",
        "designName": "Pine Ridge Sunset",
        "productType": "long_sleeve",
        "color": "Sand",
        "size": "L",
        "price": 4000,
        "qty": 1
      }
    ],
    "cartTotal": 6500
  }' | python3 -m json.tool 2>/dev/null || echo "(raw response above)"
echo ""

# ------------------------------------------
# Test 3: Cart over $100 (free shipping)
# ------------------------------------------
echo "--- Test 3: 2x Hoodies ($116.00) — Free Shipping ---"
curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "variantId": "woodland-original-hoodie-forest-green-xl",
        "designName": "Woodland Original",
        "productType": "hoodie",
        "color": "Forest Green",
        "size": "XL",
        "price": 5800,
        "qty": 2
      }
    ],
    "cartTotal": 11600
  }' | python3 -m json.tool 2>/dev/null || echo "(raw response above)"
echo ""

# ------------------------------------------
# Test 4: Exactly $100 threshold (free shipping)
# ------------------------------------------
echo "--- Test 4: Exactly \$100 threshold — Free Shipping ---"
curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "variantId": "bear-valley-crest-tee-charcoal-m",
        "designName": "Bear Valley Crest",
        "productType": "tee",
        "color": "Charcoal",
        "size": "M",
        "price": 2500,
        "qty": 4
      }
    ],
    "cartTotal": 10000
  }' | python3 -m json.tool 2>/dev/null || echo "(raw response above)"
echo ""

# ------------------------------------------
# Test 5: Empty cart (should return 400)
# ------------------------------------------
echo "--- Test 5: Empty cart — Should return 400 ---"
curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [],
    "cartTotal": 0
  }' | python3 -m json.tool 2>/dev/null || echo "(raw response above)"
echo ""

# ------------------------------------------
# Test 6: Wrong method (should return 405)
# ------------------------------------------
echo "--- Test 6: GET request — Should return 405 ---"
curl -s -X GET "$ENDPOINT" | python3 -m json.tool 2>/dev/null || echo "(raw response above)"
echo ""

# ------------------------------------------
# Test 7: Just under $100 threshold ($99.99 — standard shipping)
# ------------------------------------------
echo "--- Test 7: Just under \$100 (\$99.99) — Standard Shipping ---"
curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "variantId": "bear-valley-crest-long_sleeve-charcoal-m",
        "designName": "Bear Valley Crest",
        "productType": "long_sleeve",
        "color": "Charcoal",
        "size": "M",
        "price": 4000,
        "qty": 2
      },
      {
        "variantId": "pine-ridge-sunset-tee-sand-l",
        "designName": "Pine Ridge Sunset",
        "productType": "tee",
        "color": "Sand",
        "size": "L",
        "price": 1999,
        "qty": 1
      }
    ],
    "cartTotal": 9999
  }' | python3 -m json.tool 2>/dev/null || echo "(raw response above)"
echo ""

# ------------------------------------------
# Test 8: Large cart — 5 hoodies ($290 — free shipping)
# ------------------------------------------
echo "--- Test 8: 5x Hoodies (\$290.00) — Free Shipping ---"
curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "variantId": "woodland-original-hoodie-charcoal-m",
        "designName": "Woodland Original",
        "productType": "hoodie",
        "color": "Charcoal",
        "size": "M",
        "price": 5800,
        "qty": 3
      },
      {
        "variantId": "bear-valley-crest-hoodie-forest-green-xl",
        "designName": "Bear Valley Crest",
        "productType": "hoodie",
        "color": "Forest Green",
        "size": "XL",
        "price": 5800,
        "qty": 2
      }
    ],
    "cartTotal": 29000
  }' | python3 -m json.tool 2>/dev/null || echo "(raw response above)"
echo ""

echo "========================================="
echo " Tests complete (8 total)."
echo " Verify each response has a 'url' field"
echo " (except Tests 5-6 which should error)."
echo " Test 7 ($99.99) should show Standard Shipping."
echo " Test 8 ($290) should show Free Shipping."
echo "========================================="
