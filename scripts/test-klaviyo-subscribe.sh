#!/usr/bin/env bash
# Woodland Kin — Klaviyo Email Subscription Tests
# Usage: ./scripts/test-klaviyo-subscribe.sh [--email test@example.com]
# Requires: netlify dev running on localhost:8888

BASE_URL="${BASE_URL:-http://localhost:8888}"
ENDPOINT="$BASE_URL/.netlify/functions/subscribe-email"
TEST_EMAIL="test+woodland@example.com"

# Parse optional --email argument
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --email) TEST_EMAIL="$2"; shift ;;
    *) ;;
  esac
  shift
done

echo "========================================="
echo " Woodland Kin — Klaviyo Subscribe Tests"
echo " Target: $ENDPOINT"
echo " Test email: $TEST_EMAIL"
echo "========================================="
echo ""

# ------------------------------------------
# Test 1: Valid email subscription
# ------------------------------------------
echo "--- Test 1: Valid email ($TEST_EMAIL) ---"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$TEST_EMAIL\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

echo "Status: $HTTP_CODE"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "[PASS] Subscription returned 200."
else
  echo "[FAIL] Expected 200, got $HTTP_CODE."
fi
echo ""

# ------------------------------------------
# Test 2: Duplicate email (idempotent)
# ------------------------------------------
echo "--- Test 2: Duplicate email (same address, should be idempotent) ---"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$TEST_EMAIL\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

echo "Status: $HTTP_CODE"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "[PASS] Duplicate subscription handled gracefully."
else
  echo "[WARN] Duplicate email returned $HTTP_CODE — check for idempotency."
fi
echo ""

# ------------------------------------------
# Test 3: Invalid email (no @ symbol)
# ------------------------------------------
echo "--- Test 3: Invalid email (no @ symbol) ---"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{"email": "notanemail"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

echo "Status: $HTTP_CODE"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [[ "$HTTP_CODE" == "400" ]]; then
  echo "[PASS] Invalid email correctly rejected with 400."
elif [[ "$HTTP_CODE" == "200" ]]; then
  echo "[WARN] Invalid email returned 200 — consider stricter validation."
else
  echo "[INFO] Got $HTTP_CODE."
fi
echo ""

# ------------------------------------------
# Test 4: Empty body
# ------------------------------------------
echo "--- Test 4: Empty body ---"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{}')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

echo "Status: $HTTP_CODE"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [[ "$HTTP_CODE" == "400" ]]; then
  echo "[PASS] Empty body correctly rejected with 400."
elif [[ "$HTTP_CODE" == "200" ]]; then
  echo "[WARN] Empty body returned 200 — check validation."
else
  echo "[INFO] Got $HTTP_CODE."
fi
echo ""

# ------------------------------------------
# Test 5: GET request (wrong method)
# ------------------------------------------
echo "--- Test 5: GET request (should return 405) ---"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$ENDPOINT")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

echo "Status: $HTTP_CODE"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
echo ""

if [[ "$HTTP_CODE" == "405" ]]; then
  echo "[PASS] Correctly rejected GET request."
else
  echo "[INFO] Got $HTTP_CODE (consider adding method validation)."
fi
echo ""

echo "========================================="
echo " Klaviyo subscribe tests complete."
echo ""
echo " Manual verification:"
echo "   1. Check Klaviyo Dashboard → Lists & Segments"
echo "      → Newsletter list for test profile"
echo "   2. If Welcome Sequence flow is active, check"
echo "      inbox for welcome email"
echo "========================================="
