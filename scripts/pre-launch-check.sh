#!/usr/bin/env bash
# Woodland Kin — Pre-Launch Verification Checklist
# Usage: ./scripts/pre-launch-check.sh
#
# Runs automated checks to verify the project is ready for production deployment.
# All checks must pass before switching to live API keys and deploying.

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass() {
  echo "  [PASS] $1"
  ((PASS_COUNT++))
}

fail() {
  echo "  [FAIL] $1"
  ((FAIL_COUNT++))
}

warn() {
  echo "  [WARN] $1"
  ((WARN_COUNT++))
}

echo "========================================="
echo " Woodland Kin — Pre-Launch Check"
echo "========================================="
echo ""

# ------------------------------------------
# 1. Git status is clean
# ------------------------------------------
echo "--- Check 1: Git status ---"
if [[ -z $(git status --porcelain 2>/dev/null) ]]; then
  pass "Working directory is clean (no uncommitted changes)"
else
  fail "Uncommitted changes detected. Commit or stash before deploying."
  git status --short 2>/dev/null | head -10 | sed 's/^/         /'
fi
echo ""

# ------------------------------------------
# 2. .env is not tracked by git
# ------------------------------------------
echo "--- Check 2: .env not in git ---"
if [[ -z $(git ls-files .env 2>/dev/null) ]]; then
  pass ".env is not tracked by git"
else
  fail ".env IS tracked by git! Remove it: git rm --cached .env"
fi
echo ""

# ------------------------------------------
# 3. season.ts uses real date logic (not forced)
# ------------------------------------------
echo "--- Check 3: season.ts uses live date logic ---"
if grep -q "new Date()" src/lib/season.ts 2>/dev/null; then
  pass "season.ts uses new Date() (live date logic)"
else
  if grep -q 'return "light"' src/lib/season.ts 2>/dev/null || grep -q 'return "dark"' src/lib/season.ts 2>/dev/null; then
    fail "season.ts has a forced theme override! Revert with: ./scripts/test-theme.sh --revert"
  else
    warn "Could not confirm date logic in season.ts. Check manually."
  fi
fi
echo ""

# ------------------------------------------
# 4. Build succeeds
# ------------------------------------------
echo "--- Check 4: Production build ---"
if npx astro build 2>&1 | tail -1 | grep -qi "complete\|done\|success"; then
  pass "npx astro build succeeded"
else
  # Try again checking exit code
  if npx astro build > /dev/null 2>&1; then
    pass "npx astro build succeeded"
  else
    fail "npx astro build failed! Fix build errors before deploying."
  fi
fi
echo ""

# ------------------------------------------
# 5. No console.log in Netlify functions
# ------------------------------------------
echo "--- Check 5: No console.log in serverless functions ---"
CONSOLE_LOGS=$(grep -rn "console\.log" netlify/functions/ 2>/dev/null | grep -v "node_modules" || true)
if [[ -z "$CONSOLE_LOGS" ]]; then
  pass "No console.log found in netlify/functions/"
else
  LOG_COUNT=$(echo "$CONSOLE_LOGS" | wc -l | tr -d ' ')
  warn "$LOG_COUNT console.log statement(s) found in netlify/functions/."
  echo "$CONSOLE_LOGS" | head -5 | sed 's/^/         /'
  echo "         Consider converting to console.error for production logging."
fi
echo ""

# ------------------------------------------
# 6. robots.txt exists
# ------------------------------------------
echo "--- Check 6: robots.txt ---"
if [[ -f "public/robots.txt" ]]; then
  pass "public/robots.txt exists"
else
  fail "public/robots.txt not found! Create it before deploying."
fi
echo ""

# ------------------------------------------
# 7. Apple Pay domain verification file
# ------------------------------------------
echo "--- Check 7: Apple Pay verification file ---"
if [[ -f "public/.well-known/apple-developer-merchantid-domain-association" ]]; then
  pass "Apple Pay domain verification file exists"
else
  warn "Apple Pay verification file not found at public/.well-known/apple-developer-merchantid-domain-association"
  echo "         Download from Stripe Dashboard → Settings → Payment Methods → Apple Pay"
  echo "         (Skip if not using Apple Pay)"
fi
echo ""

# ------------------------------------------
# 8. Printful variant map — check for placeholder IDs
# ------------------------------------------
echo "--- Check 8: Printful variant mapping ---"
PLACEHOLDER_COUNT=$(grep -c "10000[0-9]" src/data/printful-map.ts 2>/dev/null || echo "0")
if [[ "$PLACEHOLDER_COUNT" -gt 0 ]]; then
  warn "$PLACEHOLDER_COUNT placeholder Printful variant IDs found (100000-range)."
  echo "         Run: npx tsx scripts/verify-variant-map.ts"
  echo "         Replace with real Printful sync variant IDs before launch."
else
  pass "No placeholder Printful variant IDs detected"
fi
echo ""

# ------------------------------------------
# 9. .gitignore includes .env
# ------------------------------------------
echo "--- Check 9: .gitignore includes .env ---"
if grep -q "^\.env$" .gitignore 2>/dev/null || grep -q "^\.env " .gitignore 2>/dev/null; then
  pass ".env is listed in .gitignore"
else
  fail ".env is NOT in .gitignore! Add it immediately."
fi
echo ""

# ------------------------------------------
# 10. Test scripts are executable
# ------------------------------------------
echo "--- Check 10: Script permissions ---"
SCRIPTS_OK=true
for SCRIPT in scripts/test-checkout.sh scripts/test-webhook.sh scripts/test-theme.sh scripts/test-printful-webhook.sh scripts/test-klaviyo-subscribe.sh scripts/test-e2e-pipeline.sh scripts/load-test.sh scripts/lighthouse-audit.sh; do
  if [[ -f "$SCRIPT" && ! -x "$SCRIPT" ]]; then
    echo "         Not executable: $SCRIPT"
    SCRIPTS_OK=false
  fi
done
if $SCRIPTS_OK; then
  pass "All test scripts are executable"
else
  warn "Some scripts lack execute permission. Run: chmod +x scripts/*.sh"
fi
echo ""

# ------------------------------------------
# Summary
# ------------------------------------------
echo "========================================="
echo " PRE-LAUNCH CHECK SUMMARY"
echo "========================================="
echo ""
echo "  Passed:   $PASS_COUNT"
echo "  Warnings: $WARN_COUNT"
echo "  Failed:   $FAIL_COUNT"
echo ""

if [[ $FAIL_COUNT -eq 0 && $WARN_COUNT -eq 0 ]]; then
  echo "  ALL CHECKS PASSED. Ready for launch!"
  echo ""
  exit 0
elif [[ $FAIL_COUNT -eq 0 ]]; then
  echo "  No failures, but $WARN_COUNT warning(s) to review."
  echo "  Proceed with caution."
  echo ""
  exit 0
else
  echo "  $FAIL_COUNT check(s) FAILED. Fix before deploying."
  echo ""
  exit 1
fi
