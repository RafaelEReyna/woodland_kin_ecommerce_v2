#!/usr/bin/env bash
# Woodland Kin — End-to-End Order Pipeline Test
# Usage: ./scripts/test-e2e-pipeline.sh
#
# Tests the full checkout → webhook → Printful → Klaviyo pipeline locally.
#
# Prerequisites:
#   1. netlify dev running (Terminal 1) — site at localhost:8888
#   2. stripe listen --forward-to localhost:8888/.netlify/functions/stripe-webhook (Terminal 2)
#   3. .env populated with all keys

set -e

BASE_URL="${BASE_URL:-http://localhost:8888}"
CHECKOUT_ENDPOINT="$BASE_URL/.netlify/functions/create-checkout-session"
HELLO_ENDPOINT="$BASE_URL/.netlify/functions/hello"

echo "========================================="
echo " Woodland Kin — E2E Pipeline Test"
echo "========================================="
echo ""

# ------------------------------------------
# Prerequisites check
# ------------------------------------------
echo "--- Checking prerequisites ---"
echo ""

# Check netlify dev is running
echo -n "Netlify dev (localhost:8888): "
if curl -s --max-time 3 "$HELLO_ENDPOINT" | grep -q "Woodland Kin"; then
  echo "RUNNING"
else
  echo "NOT FOUND"
  echo ""
  echo "ERROR: netlify dev does not appear to be running."
  echo "Start it with: netlify dev"
  exit 1
fi

# Check stripe listen is running (best effort)
echo -n "Stripe CLI listener: "
if pgrep -f "stripe listen" > /dev/null 2>&1; then
  echo "RUNNING"
else
  echo "NOT DETECTED (may be running in another terminal)"
  echo "  If not running, start with:"
  echo "  stripe listen --forward-to localhost:8888/.netlify/functions/stripe-webhook"
  echo ""
fi

echo ""

# ------------------------------------------
# Step 1: Create checkout session
# ------------------------------------------
echo "--- Step 1: Creating Stripe checkout session ---"
echo ""

RESPONSE=$(curl -s -X POST "$CHECKOUT_ENDPOINT" \
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
  }')

CHECKOUT_URL=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('url', ''))" 2>/dev/null)

if [[ -z "$CHECKOUT_URL" ]]; then
  echo "[FAIL] Could not create checkout session."
  echo "Response: $RESPONSE"
  exit 1
fi

echo "[PASS] Checkout session created."
echo ""

# ------------------------------------------
# Step 2: Manual payment completion
# ------------------------------------------
echo "--- Step 2: Complete payment in browser ---"
echo ""
echo "Open this URL in your browser and complete payment"
echo "with test card 4242 4242 4242 4242:"
echo ""
echo "  $CHECKOUT_URL"
echo ""
echo "Use any future expiry date, any 3-digit CVC, any ZIP."
echo ""
read -p "Press Enter after completing payment (or Ctrl+C to cancel)..."
echo ""

# ------------------------------------------
# Step 3: Wait for webhook processing
# ------------------------------------------
echo "--- Step 3: Waiting for webhook processing (5 seconds) ---"
sleep 5
echo "Done."
echo ""

# ------------------------------------------
# Step 4: Verification checklist
# ------------------------------------------
echo "========================================="
echo " VERIFICATION CHECKLIST"
echo "========================================="
echo ""
echo " Check in netlify dev terminal (Terminal 1):"
echo "   [ ] [Order Received] log with order ID and customer email"
echo "   [ ] [Printful] log with order forwarding result"
echo "   [ ]   If Printful sandbox key is set: 'Order created successfully'"
echo "   [ ]   If no key / placeholder: error log (expected)"
echo "   [ ] No unhandled exceptions or crashes"
echo ""
echo " Check in stripe listen terminal (Terminal 2):"
echo "   [ ] checkout.session.completed event received"
echo "   [ ] Event status: 200 OK"
echo ""
echo " Check in external dashboards:"
echo "   [ ] Stripe Dashboard → Payments → test payment visible"
echo "   [ ] Printful Dashboard → Orders → test order visible"
echo "   [ ]   (only if using real sandbox API key)"
echo "   [ ] Klaviyo Dashboard → Activity Feed → 'Placed Order' event"
echo "   [ ]   (only if Klaviyo keys are configured)"
echo ""
echo " If redirect to /order/success worked:"
echo "   [ ] Success page displayed 'Thank you for your order!'"
echo "   [ ] Cart was cleared in browser"
echo ""
echo "========================================="
echo " E2E pipeline test complete."
echo "========================================="
