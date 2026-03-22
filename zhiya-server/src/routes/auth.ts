import { Hono } from 'hono';
import { db } from '../db/client.js';
import { users } from '../db/schema.js';
import { eq } from 'drizzle-orm';
import { generateToken } from '../middleware/auth.js';
import { v4 as uuid } from 'uuid';

const auth = new Hono();

auth.post('/register', async (c) => {
  const body = await c.req.json();
  const { deviceId, name, subjects } = body;

  if (!deviceId) {
    return c.json({ error: 'deviceId is required' }, 400);
  }

  // Check existing
  const existing = await db.select().from(users).where(eq(users.deviceId, deviceId));
  if (existing.length > 0) {
    const token = generateToken({ userId: existing[0].id, deviceId });
    return c.json({ token, userId: existing[0].id });
  }

  // Create new user
  const userId = uuid();
  const now = new Date().toISOString();
  await db.insert(users).values({
    id: userId,
    deviceId,
    name: name || null,
    subjects: subjects ? JSON.stringify(subjects) : null,
    joinDate: now,
    createdAt: now,
  });

  const token = generateToken({ userId, deviceId });
  return c.json({ token, userId });
});

export default auth;
