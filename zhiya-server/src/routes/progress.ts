import { Hono } from 'hono';
import { db } from '../db/client.js';
import { progress } from '../db/schema.js';
import { eq } from 'drizzle-orm';
import { v4 as uuid } from 'uuid';

const progressRoutes = new Hono();

progressRoutes.post('/record', async (c) => {
  const userId = c.get('userId') as string;
  const body = await c.req.json();
  const { paperId, chapterId, kpId, questionId, correct, selectedIndex } = body;

  if (!paperId || !chapterId || !kpId || !questionId || correct === undefined || selectedIndex === undefined) {
    return c.json({ error: 'Missing required fields' }, 400);
  }

  await db.insert(progress).values({
    id: uuid(),
    userId,
    paperId,
    chapterId,
    kpId,
    questionId,
    correct,
    selectedIndex,
    timestamp: new Date().toISOString(),
  });

  return c.json({ success: true });
});

progressRoutes.get('/stats', async (c) => {
  const userId = c.get('userId') as string;
  const records = await db.select().from(progress).where(eq(progress.userId, userId));

  const totalAnswered = records.length;
  const totalCorrect = records.filter((r) => r.correct).length;
  const accuracy = totalAnswered > 0 ? totalCorrect / totalAnswered : 0;

  // Count unique wrong questions not yet answered correctly
  const correctIds = new Set(records.filter((r) => r.correct).map((r) => r.questionId));
  const wrongIds = new Set(
    records
      .filter((r) => !r.correct && !correctIds.has(r.questionId))
      .map((r) => r.questionId)
  );

  return c.json({
    totalAnswered,
    totalCorrect,
    accuracy: Math.round(accuracy * 100) / 100,
    wrongCount: wrongIds.size,
  });
});

export default progressRoutes;
