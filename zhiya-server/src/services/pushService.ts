// Push notification service — polls Synapse for proactive messages and dispatches via APNs

const SYNAPSE_URL = process.env.SYNAPSE_URL || '';
const APNS_KEY_ID = process.env.APNS_KEY_ID || '';
const APNS_TEAM_ID = process.env.APNS_TEAM_ID || '';
const APNS_BUNDLE_ID = process.env.APNS_BUNDLE_ID || 'com.zhiya.app';
const POLL_INTERVAL_MS = 60_000; // Check every minute

interface PendingNotification {
  id: string;
  userId: string;
  type: string; // morning_greeting, weekly_letter, review_reminder, evening_reflection
  title: string;
  body: string;
  data?: Record<string, unknown>;
  createdAt: string;
}

// In-memory device token registry (in production, persist to DB)
const deviceTokens = new Map<string, string>();

export function registerDeviceToken(userId: string, token: string) {
  deviceTokens.set(userId, token);
}

export function unregisterDeviceToken(userId: string) {
  deviceTokens.delete(userId);
}

// Send push notification via APNs HTTP/2
async function sendAPNs(deviceToken: string, notification: PendingNotification): Promise<boolean> {
  if (!APNS_KEY_ID || !APNS_TEAM_ID) {
    console.log(`[PushService] APNs not configured. Would send to ${deviceToken}:`, notification.title);
    return false;
  }

  try {
    // In production, use proper APNs JWT signing with the .p8 key
    // For now, log the notification
    console.log(`[PushService] Sending APNs push:`, {
      token: deviceToken.slice(0, 8) + '...',
      title: notification.title,
      body: notification.body.slice(0, 100),
      type: notification.type,
    });

    // APNs HTTP/2 request would go here:
    // POST https://api.push.apple.com/3/device/{deviceToken}
    // Headers: authorization: bearer {jwt}, apns-topic: {bundleId}
    // Body: { aps: { alert: { title, body }, sound: "default" }, type, data }

    return true;
  } catch (err) {
    console.error('[PushService] APNs send failed:', err);
    return false;
  }
}

// Poll Synapse for pending notifications and dispatch
async function pollAndDispatch() {
  if (!SYNAPSE_URL) return;

  try {
    const since = new Date(Date.now() - POLL_INTERVAL_MS * 2).toISOString();

    // Get all registered users
    for (const [userId, deviceToken] of deviceTokens.entries()) {
      const response = await fetch(
        `${SYNAPSE_URL}/api/proactive/zhiya/${userId}/pending?since=${since}`,
        { headers: { 'Content-Type': 'application/json' } },
      );

      if (!response.ok) continue;

      const data = (await response.json()) as { notifications?: PendingNotification[] };
      const notifications = data.notifications || [];

      for (const notification of notifications) {
        await sendAPNs(deviceToken, notification);

        // Mark as delivered
        try {
          await fetch(
            `${SYNAPSE_URL}/api/proactive/zhiya/${userId}/delivered/${notification.id}`,
            { method: 'POST', headers: { 'Content-Type': 'application/json' } },
          );
        } catch {
          // Non-blocking
        }
      }
    }
  } catch (err) {
    console.error('[PushService] Poll error:', err);
  }
}

let pollTimer: ReturnType<typeof setInterval> | null = null;

export function startPushService() {
  if (!SYNAPSE_URL) {
    console.log('[PushService] SYNAPSE_URL not set, push service disabled');
    return;
  }

  console.log(`[PushService] Starting push polling every ${POLL_INTERVAL_MS / 1000}s`);
  pollTimer = setInterval(pollAndDispatch, POLL_INTERVAL_MS);

  // Initial poll
  pollAndDispatch();
}

export function stopPushService() {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
}
