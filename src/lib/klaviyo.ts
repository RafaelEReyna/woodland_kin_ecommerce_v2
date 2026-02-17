const KLAVIYO_API_URL = "https://a.klaviyo.com/api";

export async function trackEvent(
  eventName: string,
  email: string,
  properties: Record<string, unknown>
): Promise<void> {
  const apiKey = process.env.KLAVIYO_PRIVATE_KEY;
  if (!apiKey) {
    console.error("[Klaviyo] KLAVIYO_PRIVATE_KEY not configured");
    return;
  }

  try {
    const res = await fetch(`${KLAVIYO_API_URL}/events/`, {
      method: "POST",
      headers: {
        Authorization: `Klaviyo-API-Key ${apiKey}`,
        "Content-Type": "application/json",
        revision: "2024-02-15",
      },
      body: JSON.stringify({
        data: {
          type: "event",
          attributes: {
            metric: { data: { type: "metric", attributes: { name: eventName } } },
            profile: { data: { type: "profile", attributes: { email } } },
            properties,
          },
        },
      }),
    });

    if (!res.ok) {
      const errorBody = await res.text();
      console.error(`[Klaviyo] trackEvent "${eventName}" failed:`, errorBody);
    }
  } catch (err) {
    console.error(`[Klaviyo] trackEvent "${eventName}" error:`, err);
  }
}

export async function subscribeToList(
  email: string,
  listId: string
): Promise<void> {
  const apiKey = process.env.KLAVIYO_PRIVATE_KEY;
  if (!apiKey) {
    console.error("[Klaviyo] KLAVIYO_PRIVATE_KEY not configured");
    return;
  }

  try {
    const res = await fetch(`${KLAVIYO_API_URL}/profile-subscription-bulk-create-jobs/`, {
      method: "POST",
      headers: {
        Authorization: `Klaviyo-API-Key ${apiKey}`,
        "Content-Type": "application/json",
        revision: "2024-02-15",
      },
      body: JSON.stringify({
        data: {
          type: "profile-subscription-bulk-create-job",
          attributes: {
            profiles: {
              data: [
                {
                  type: "profile",
                  attributes: {
                    email,
                    subscriptions: {
                      email: {
                        marketing: {
                          consent: "SUBSCRIBED",
                        },
                      },
                    },
                  },
                },
              ],
            },
          },
          relationships: {
            list: {
              data: {
                type: "list",
                id: listId,
              },
            },
          },
        },
      }),
    });

    if (!res.ok) {
      const errorBody = await res.text();
      console.error("[Klaviyo] subscribeToList failed:", errorBody);
    }
  } catch (err) {
    console.error("[Klaviyo] subscribeToList error:", err);
  }
}
