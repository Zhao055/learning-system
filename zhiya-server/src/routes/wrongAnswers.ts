import { Hono } from 'hono';
import { db } from '../db/client.js';
import { progress } from '../db/schema.js';
import { eq, and } from 'drizzle-orm';

const wrongAnswers = new Hono();

wrongAnswers.get('/', async (c) => {
  const userId = c.get('userId') as string;
  const records = await db.select().from(progress).where(eq(progress.userId, userId));

  // Find wrong answers not yet corrected
  const correctIds = new Set(records.filter((r) => r.correct).map((r) => r.questionId));
  const wrongRecords = records
    .filter((r) => !r.correct && !correctIds.has(r.questionId))
    .reduce((acc, r) => {
      if (!acc.has(r.questionId)) acc.set(r.questionId, r);
      return acc;
    }, new Map());

  return c.json(Array.from(wrongRecords.values()));
});

wrongAnswers.delete('/:id', async (c) => {
  const userId = c.get('userId') as string;
  const questionId = c.req.param('id');

  // Remove all wrong records for this question
  // Note: In production, use a proper delete with conditions
  const records = await db
    .select()
    .from(progress)
    .where(and(eq(progress.userId, userId), eq(progress.questionId, questionId)));

  // Mark as correct (effectively removing from wrong list)
  if (records.length > 0) {
    const { v4: uuid2 } = await import('uuid');
    await db.insert(progress).values({
      id: uuid2(),
      userId,
      paperId: records[0].paperId,
      chapterId: records[0].chapterId,
      kpId: records[0].kpId,
      questionId,
      correct: true,
      selectedIndex: 0,
      timestamp: new Date().toISOString(),
    });
  }

  return c.json({ success: true });
});

export default wrongAnswers;
