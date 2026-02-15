# Woodland Kin — Launch Checklist

## Pre-Launch Requirements

Ensure all items in `TESTING.md` pass before proceeding.

---

## 1. DNS Configuration

- [ ] Purchase domain (e.g., `woodlandkin.com`) if not already owned
- [ ] In Netlify Dashboard → Domain Management → Add custom domain
- [ ] Update DNS records at your registrar:
  - `A` record → Netlify load balancer IP (provided in dashboard)
  - `CNAME` for `www` → `<your-site>.netlify.app`
- [ ] Enable HTTPS in Netlify → Domain Management → HTTPS
- [ ] Wait for SSL certificate provisioning (automatic via Let's Encrypt)
- [ ] Verify site loads at `https://woodlandkin.com` and `https://www.woodlandkin.com`

---

## 2. Stripe: Test → Live Mode

- [ ] In Stripe Dashboard, toggle from "Test mode" to live
- [ ] Generate live API keys:
  - `STRIPE_SECRET_KEY` → new `sk_live_` key
  - `PUBLIC_STRIPE_PUBLISHABLE_KEY` → new `pk_live_` key
- [ ] Create a live webhook endpoint:
  - URL: `https://woodlandkin.com/.netlify/functions/stripe-webhook`
  - Events to listen for: `checkout.session.completed`
- [ ] Copy the live webhook signing secret → `STRIPE_WEBHOOK_SECRET`
- [ ] Update all three keys in Netlify environment variables

---

## 3. Apple Pay / Google Pay Domain Verification

### Apple Pay
- [ ] Stripe Dashboard → Settings → Payment Methods → Apple Pay
- [ ] Add domain: `woodlandkin.com`
- [ ] Download the domain verification file
- [ ] Place at `public/.well-known/apple-developer-merchantid-domain-association`
- [ ] Deploy and verify the file is accessible at `https://woodlandkin.com/.well-known/apple-developer-merchantid-domain-association`
- [ ] Click "Verify" in Stripe Dashboard

### Google Pay
- [ ] Google Pay is enabled automatically in Stripe for verified Stripe accounts
- [ ] Verify Google Pay appears on checkout in a Chrome browser
- [ ] No additional domain verification required

---

## 4. Printful: Sandbox → Production

- [ ] In Printful Dashboard → Settings → API Access
- [ ] Ensure the API key is for your production store (not sandbox)
- [ ] Update `PRINTFUL_API_KEY` in Netlify environment variables
- [ ] Update `src/data/printful-map.ts` with real Printful sync variant IDs:
  - Each design × product type × color × size must map to a real Printful variant
  - Get variant IDs from Printful Dashboard → Products → Sync Products → each variant
- [ ] Place a test order through the live site to verify Printful receives it
- [ ] Verify shipping address passes through correctly
- [ ] Confirm the order appears in Printful Dashboard → Orders

---

## 5. Klaviyo: Activate Flows

- [ ] Verify API keys are set for production Klaviyo account:
  - `KLAVIYO_PRIVATE_KEY` in Netlify env vars
  - `PUBLIC_KLAVIYO_PUBLIC_KEY` in Netlify env vars
  - `KLAVIYO_NEWSLETTER_LIST_ID` in Netlify env vars
- [ ] In Klaviyo Dashboard, activate all flows:
  - [ ] Welcome Sequence (triggers on newsletter list subscribe)
  - [ ] Abandoned Cart (triggers on Stripe checkout abandonment)
  - [ ] Post-Purchase Thank You (triggers on "Placed Order" event)
  - [ ] Shipping Confirmation (triggers on "Order Shipped" event)
- [ ] Send a test email from each flow to verify delivery and formatting
- [ ] Verify sender domain is authenticated (SPF/DKIM/DMARC)

---

## 6. Environment Variable Swap

Update all environment variables in **Netlify Dashboard → Site Settings → Environment Variables**:

| Variable | Test Value | Live Value |
|---|---|---|
| `STRIPE_SECRET_KEY` | `sk_test_xxx` | `sk_live_xxx` |
| `STRIPE_WEBHOOK_SECRET` | `whsec_xxx` (test) | `whsec_xxx` (live endpoint) |
| `PUBLIC_STRIPE_PUBLISHABLE_KEY` | `pk_test_xxx` | `pk_live_xxx` |
| `PRINTFUL_API_KEY` | Sandbox key | Production key |
| `KLAVIYO_PRIVATE_KEY` | Test key (if applicable) | Production key |
| `PUBLIC_KLAVIYO_PUBLIC_KEY` | Test ID | Production ID |
| `KLAVIYO_NEWSLETTER_LIST_ID` | Test list ID | Production list ID |
| `PUBLIC_SITE_URL` | `http://localhost:8888` | `https://woodlandkin.com` |

- [ ] Update all variables in Netlify
- [ ] Trigger a new deploy: `netlify deploy --prod`
- [ ] Verify the site loads with production keys

---

## 7. Final Smoke Test

Perform these tests on the **live production site** after all keys are swapped:

### Critical Path
- [ ] Browse home page — loads correctly, no console errors
- [ ] Navigate to Shop — all designs display
- [ ] Open a design detail page — configurator works
- [ ] Select product type, color, size — price updates
- [ ] Add to cart — cart drawer opens with correct item
- [ ] Add more items to exceed $100 — free shipping shows
- [ ] Click Checkout — Stripe Checkout loads with correct items
- [ ] Complete payment with a real card (small order, refund after)
- [ ] Verify `/order/success` page loads
- [ ] Verify Stripe Dashboard shows the payment
- [ ] Verify Printful Dashboard receives the order
- [ ] Verify Klaviyo logs "Placed Order" event
- [ ] Verify confirmation email is received
- [ ] Refund the test order in Stripe Dashboard

### Secondary Checks
- [ ] All static pages load: About, Contact, FAQ, Shipping & Returns, Size Guide
- [ ] Contact form renders correctly
- [ ] Email capture on home page submits successfully
- [ ] Mobile responsive — test on real iPhone and Android device
- [ ] Theme is correct for current season (dark: Oct-Mar, light: Apr-Sep)
- [ ] Sitemap accessible at `/sitemap-index.xml`
- [ ] Robots.txt accessible at `/robots.txt`
- [ ] No `console.log` output in browser DevTools (production)
- [ ] Lighthouse Performance ≥ 90 on live URL
- [ ] Lighthouse Accessibility ≥ 90 on live URL

---

## 8. Go-Live

- [ ] All smoke tests pass
- [ ] Remove any test/debug code from `season.ts` (no forced theme)
- [ ] Verify `.env` is NOT committed to git
- [ ] Create a git tag: `git tag -a v1.0.0 -m "Launch release"`
- [ ] Push tag: `git push origin v1.0.0`
- [ ] Monitor Netlify deploy logs for errors
- [ ] Monitor Stripe Dashboard for first real orders
- [ ] Monitor Printful Dashboard for order fulfillment
- [ ] Celebrate — you're live!

---

## Post-Launch Monitoring

- **Stripe:** Check daily for failed payments, disputes, or webhook failures
- **Printful:** Monitor order status and shipping times
- **Klaviyo:** Check email deliverability and flow performance weekly
- **Netlify:** Review function invocation logs for errors
- **Lighthouse:** Run monthly audits to maintain performance scores
