import { Hono } from 'hono';
import { generateGreeting, getRelationshipStage } from '../services/companionService.js';
import { analyzeEmotion } from '../services/emotionService.js';
import { db } from '../db/client.js';
import { users } from '../db/schema.js';
import { eq } from 'drizzle-orm';

const companion = new Hono();

companion.get('/greeting', async (c) => {
  const userId = c.get('userId') as string;
  const greeting = await generateGreeting(userId);
  return c.json(greeting);
});

companion.get('/stage', async (c) => {
  const userId = c.get('userId') as string;
  const user = await db.select().from(users).where(eq(users.id, userId));

  if (!user.length) {
    return c.json({ error: 'User not found' }, 404);
  }

  const u = user[0];
  const daysSince = Math.floor(
    (Date.now() - new Date(u.joinDate).getTime()) / 86400000
  );
  const stage = getRelationshipStage(daysSince);

  return c.json({
    ...stage,
    daysSinceJoin: daysSince,
    treeLevel: u.treeLevel ?? 1,
    relationshipDepth: Math.min(1, daysSince / 365),
  });
});

companion.post('/emotion', async (c) => {
  const body = await c.req.json();
  const { text, context } = body;

  if (!text) {
    return c.json({ error: 'text is required' }, 400);
  }

  const analysis = analyzeEmotion(text, context);
  return c.json(analysis);
});

companion.get('/weekly-letter', async (c) => {
  const userId = c.get('userId') as string;

  // Generate a weekly letter based on recent activity
  // For now return a template. In production, this would use AI + progress data
  const user = await db.select().from(users).where(eq(users.id, userId));
  const name = user[0]?.name || '同学';

  return c.json({
    letter: {
      topicsStudied: ['暂无本周学习数据'],
      observation: `${name}，保持学习的节奏就好。`,
      suggestion: '下周可以从错题本开始，巩固薄弱环节。',
      closing: '这周辛苦了。下周见。',
    },
  });
});

export default companion;
