#!/usr/bin/env node
/**
 * IgnisTwin FCM sender (koi billing/card nahi chahiye — sirf free service account key).
 *
 * Ye script Realtime Database ke /sensors ko dekhta hai. Jab flame aata hai ya smoke
 * threshold cross karta hai, to FCM (HTTP v1) se app ko notification bhejta hai.
 *
 *   Node 18+ chahiye (built-in fetch). Koi npm install nahi.
 *
 * STEP 1: Service account key download karein (free, Spark plan mein bhi chalti hai):
 *   Firebase console -> Project settings -> Service accounts -> Generate new private key
 *   File ko project mein rakhein, e.g. tool/service-account.json  (git mein commit na karein!)
 *
 * STEP 2: Chalayein:
 *   node tool/fcm_sender.js tool/service-account.json
 *
 * Optional env:
 *   SMOKE_THRESHOLD=1500   SMOKE_THRESHOLD threshold (0-4095)
 *   POLL_MS=2000           kitne ms baad database check ho
 *   TOPIC=home_alerts      FCM topic (app isi par subscribe hai)
 */

const fs = require('node:fs');
const crypto = require('node:crypto');

const keyPath = process.argv[2] || process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!keyPath) {
  console.error('Service account JSON ka path dein: node tool/fcm_sender.js path/to/key.json');
  process.exit(1);
}

const sa = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
const projectId = sa.project_id;
const topic = process.env.TOPIC || 'home_alerts';
const smokeThreshold = Number(process.env.SMOKE_THRESHOLD || 1500);
const pollMs = Number(process.env.POLL_MS || 2000);
// Database URL: apne aap projectId se bana lete hain, ya DATABASE_URL env se
const dbUrl = (
  process.env.DATABASE_URL ||
  `https://${projectId}-default-rtdb.asia-southeast1.firebasedatabase.app`
).replace(/\/$/, '');

// ---------- OAuth 2.0 access token (service account se) ----------
let cached = { token: null, exp: 0 };

const b64url = (buf) =>
  Buffer.from(buf).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

async function accessToken() {
  const now = Math.floor(Date.now() / 1000);
  if (cached.token && cached.exp - 60 > now) return cached.token;

  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );

  const signature = crypto
    .createSign('RSA-SHA256')
    .update(`${header}.${claim}`)
    .sign(sa.private_key);
  const jwt = `${header}.${claim}.${b64url(signature)}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  const json = await res.json();
  if (!json.access_token) {
    throw new Error(`Token mila nahi: ${JSON.stringify(json)}`);
  }
  cached = { token: json.access_token, exp: now + (json.expires_in || 3600) };
  return cached.token;
}

// ---------- FCM HTTP v1 send ----------
async function sendNotification(title, body, data = {}) {
  const token = await accessToken();
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          topic,
          notification: { title, body },
          data,
          android: { priority: 'high', notification: { channel_id: 'ignis_alerts_v4' } },
        },
      }),
    },
  );
  const text = await res.text();
  if (!res.ok) throw new Error(`FCM ${res.status}: ${text}`);
  console.log(`✅ Notification bhej di: ${title} — ${body}`);
}

// ---------- Database watch ----------
let last = { flame: false, alerting: false };

async function readSensors() {
  const res = await fetch(`${dbUrl}/sensors.json?auth=${sa.api_key || ''}`);
  if (!res.ok) return null;
  return res.json();
}

async function tick() {
  try {
    const d = await readSensors();
    if (!d) return;

    const flame = d.flame === true || d.flame === 1 || d.flame === 'true';
    const smoke = Number(d.smoke) || 0;
    const alerting = flame || smoke >= smokeThreshold;

    // Sirf badalne par bhejein (har 2 second spam na ho)
    if (alerting && !last.alerting) {
      const title = flame ? '🔥 Flame detected' : '💨 Smoke level high';
      const body = `Bedroom · smoke ${smoke}${flame ? ' · flame ON' : ''}`;
      await sendNotification(title, body, {
        flame: String(flame),
        smoke: String(smoke),
      });
    } else if (!alerting && last.alerting) {
      console.log('ℹ️  Conditions normal ho gayin (koi notification nahi bheji).');
    }

    last = { flame, alerting };
  } catch (e) {
    console.error('⚠️ ', e.message);
  }
}

console.log(`📡 Dekh rahe hain: ${dbUrl}/sensors  (topic: ${topic}, threshold: ${smokeThreshold})`);
tick();
setInterval(tick, pollMs);
