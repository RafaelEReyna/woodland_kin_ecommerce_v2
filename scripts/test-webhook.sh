#!/usr/bin/env bash
# Woodland Kin — Stripe Webhook Test Script
# Usage: ./scripts/test-webhook.sh
#
# Prerequisites:
#   1. Install Stripe CLI: brew install stripe/stripe-cli/stripe
#   2. Login: stripe login
#   3. Start local listener: stripe listen --forward-to localhost:8888/.netlify/functions/stripe-webhook
#   4. Copy the webhook signing secret from the CLI output and set it as STRIPE_WEBHOOK_SECRET in .env
#   5. Run netlify dev in a separate terminal

BASE_URL="${BASE_URL:-http://localhost:8888}"

echo "========================================="
echo " Woodland Kin — Webhook Tests"
echo " Target: $BASE_URL"
echo "========================================="
echo ""

# ------------------------------------------
# Prerequisite check
# ------------------------------------------
if ! command -v stripe &>/dev/null; then
  echo "ERROR: Stripe CLI not installed."
  echo "Install with: brew install stripe/stripe-cli/stripe"
  exit 1
fi

echo "Checking Stripe CLI login status..."
stripe config --list 2>/dev/null || {
  echo "WARNING: You may need to run 'stripe login' first."
}
echo ""

# ------------------------------------------
# Test 1: Trigger checkout.session.completed
# ------------------------------------------
echo "--- Test 1: Trigger checkout.session.completed ---"
echo "This will create a real test event via Stripe's test clock."
echo ""
stripe trigger checkout.session.completed
echo ""

# ------------------------------------------
# Test 2: Trigger payment_intent.succeeded
# ------------------------------------------
echo "--- Test 2: Trigger payment_intent.succeeded ---"
stripe trigger payment_intent.succeeded
echo ""

# ------------------------------------------
# Test 3: Trigger payment_intent.payment_failed
# ------------------------------------------
echo "--- Test 3: Trigger payment_intent.payment_failed ---"
stripe trigger payment_intent.payment_failed
echo ""

echo "========================================="
echo " Webhook tests triggered."
echo ""
echo " Check your terminal running 'stripe listen'"
echo " and 'netlify dev' for event logs."
echo ""
echo " Manual verification steps:"
echo "   1. Look for [Order Received] log in netlify dev output"
echo "   2. Look for [Printful] log showing order forwarding"
echo "   3. Check Klaviyo dashboard for 'Placed Order' event"
echo "========================================="
