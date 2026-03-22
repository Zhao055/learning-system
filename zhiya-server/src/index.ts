import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { serve } from '@hono/node-server';
import auth from './routes/auth.js';
import questionBanks from './routes/questionBanks.js';
import chat from './routes/chat.js';
import progressRoutes from './routes/progress.js';
import wrongAnswers from './routes/wrongAnswers.js';
import companion from './routes/companion.js';
import growth from './routes/growth.js';
import synapse from './routes/synapse.js';
import { authMiddleware } from './middleware/auth.js';
import { complianceMiddleware } from './middleware/compliance.js';
import { startPushService, registerDeviceToken } from './services/pushService.js';

// Initialize database tables
import { db } from './db/client.js';
import { sql } from 'drizzle-orm';

// Create tables if not exist
db.run(sql`CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  device_id TEXT NOT NULL UNIQUE,
  name TEXT,
  subjects TEXT,
  goals TEXT,
  join_date TEXT NOT NULL,
  exam_date TEXT,
  tree_level INTEGER DEFAULT 1,
  relationship_stage TEXT DEFAULT 'seed',
  created_at TEXT NOT NULL
)`);

db.run(sql`CREATE TABLE IF NOT EXISTS progress (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  paper_id TEXT NOT NULL,
  chapter_id TEXT NOT NULL,
  kp_id TEXT NOT NULL,
  question_id TEXT NOT NULL,
  correct INTEGER NOT NULL,
  selected_index INTEGER NOT NULL,
  timestamp TEXT NOT NULL
)`);

db.run(sql`CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  type TEXT NOT NULL,
  context TEXT,
  messages TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)`);

db.run(sql`CREATE TABLE IF NOT EXISTS memories (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  dimension TEXT,
  emotional_weight REAL DEFAULT 0.5,
  timestamp TEXT NOT NULL
)`);

db.run(sql`CREATE TABLE IF NOT EXISTS milestones (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  type TEXT NOT NULL,
  achieved_date TEXT NOT NULL,
  celebration_shown INTEGER DEFAULT 0
)`);

db.run(sql`CREATE TABLE IF NOT EXISTS companion_state (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) UNIQUE,
  emotional_profile TEXT,
  growth_tree TEXT,
  weekly_letters TEXT,
  last_greeting TEXT,
  last_active_at TEXT
)`);

db.run(sql`CREATE TABLE IF NOT EXISTS growth_snapshots (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  dimension TEXT NOT NULL,
  score REAL NOT NULL,
  details TEXT,
  date TEXT NOT NULL
)`);

const app = new Hono();

// Middleware
app.use('*', cors());
app.use('*', logger());

// Health check
app.get('/', (c) => c.json({ name: '知芽 Synapse Server', version: '1.0.0', status: 'running' }));
app.get('/health', (c) => c.json({ status: 'ok' }));

// Public routes
app.route('/auth', auth);

// Protected routes
app.use('/api/*', authMiddleware);
app.use('/api/chat/*', complianceMiddleware);

app.route('/api', questionBanks);
app.route('/api/chat', chat);
app.route('/api/progress', progressRoutes);
app.route('/api/wrong-answers', wrongAnswers);
app.route('/api/companion', companion);
app.route('/api/growth', growth);
app.route('/api/synapse', synapse);

// Device token registration for push notifications
app.post('/api/device-token', async (c) => {
  const userId = c.get('userId') as string;
  const { token } = await c.req.json();
  if (token) {
    registerDeviceToken(userId, token);
    return c.json({ success: true });
  }
  return c.json({ error: 'token is required' }, 400);
});

// Start server
const port = parseInt(process.env.PORT || '3000');
console.log(`🌱 知芽 Synapse Server starting on port ${port}...`);

serve({
  fetch: app.fetch,
  port,
});

console.log(`🌱 知芽 Synapse Server running at http://localhost:${port}`);

// Start push notification polling if Synapse is configured
startPushService();
