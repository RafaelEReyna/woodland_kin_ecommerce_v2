#!/usr/bin/env bash
# Woodland Kin — Printful Webhook Simulation Test
# Usage: ./scripts/test-printful-webhook.sh
# Requires: netlify dev running on localhost:8888

BASE_URL="${BASE_URL:-http://localhost:8888}"
ENDPOINT="$BASE_URL/.netlify/functions/printful-webhook"

echo "========================================="
echo " Woodland Kin — Printful Webhook Tests"
echo " Target: $ENDPOINT"
echo "========================================="
echo ""

# ------------------------------------------
# Test 1: package_shipped event (valid)
# ------------------------------------------
echo "--- Test 1: package_shipped event (valid payload) ---"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "package_shipped",
    "data": {
      "shipment": {
        "order": { "external_id": "cs_test_simulated_001" },
        "tracking_number": "1Z999AA10123456784",
        "carrier": "UPS",
        "service": "UPS Ground"
      }
    }
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

echo "Status: $HTTP_CODE"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "[PASS] Webhook returned 200."
else
  echo "[FAIL] Expected 200, got $HTTP_CODE."
fi
echo ""

# ------------------------------------------
# Test 2: Unhandled event type
# ------------------------------------------
echo "--- Test 2: Unhandled event type (order_created) ---"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "order_created",
    "data": {
      "order": { "id": 12345, "external_id": "cs_test_simulated_002" }
    }
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

echo "Status: $HTTP_CODE"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "[PASS] Webhook returned 200 (acknowledged, no action)."
else
  echo "[WARN] Unexpected status $HTTP_CODE for unhandled event type."
fi
echo ""

# ------------------------------------------
# Test 3: GET request (should fail)
# ------------------------------------------
echo "--- Test 3: GET request (should return 405) ---"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$ENDPOINT")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

echo "Status: $HTTP_CODE"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [[ "$HTTP_CODE" == "405" ]]; then
  echo "[PASS] Correctly rejected GET request."
elif [[ "$HTTP_CODE" == "200" ]]; then
  echo "[WARN] GET returned 200 — consider adding method validation."
else
  echo "[INFO] Got $HTTP_CODE."
fi
echo ""

echo "========================================="
echo " Printful webhook tests complete."
echo ""
echo " Manual verification:"
echo "   1. Check netlify dev terminal for [Printful Shipped] log"
echo "   2. Check Klaviyo Dashboard → Activity Feed for"
echo "      'Order Shipped' event (Test 1 only)"
echo "========================================="
