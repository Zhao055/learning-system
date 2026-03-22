// Layer 6: Proactive Intelligence
import { db } from '../db/client.js';
import { progress, users } from '../db/schema.js';
import { eq } from 'drizzle-orm';

export interface ProactiveNotification {
  type: 'daily_plan' | 'gentle_recall' | 'exam_countdown' | 'struggle_detected';
  message: string;
  priority: number; // 1-5
}

export async function generateDailyNotification(userId: string): Promise<ProactiveNotification | null> {
  const user = await db.select().from(users).where(eq(users.id, userId));
  if (!user.length) return null;

  const u = user[0];
  const name = u.name || '同学';
  const records = await db.select().from(progress).where(eq(progress.userId, userId));

  // Check last activity
  const lastRecord = records.sort((a, b) =>
    new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
  )[0];

  if (lastRecord) {
    const daysSinceLastActivity = Math.floor(
      (Date.now() - new Date(lastRecord.timestamp).getTime()) / 86400000
    );

    // Gentle recall (3+ days inactive)
    if (daysSinceLastActivity >= 3) {
      return {
        type: 'gentle_recall',
        message: `好几天没见了，${name}。没事，什么时候想回来，我都在。`,
        priority: 2,
      };
    }
  }

  // Exam countdown
  if (u.examDate) {
    const daysToExam = Math.ceil(
      (new Date(u.examDate).getTime() - Date.now()) / 86400000
    );
    if (daysToExam > 0 && daysToExam <= 30) {
      // Find weak areas
      const wrongCount = records.filter((r) => !r.correct).length;
      return {
        type: 'exam_countdown',
        message: `距离考试还有${daysToExam}天。${wrongCount > 0 ? `错题本里有${wrongCount}道题可以复习。` : '继续保持！'}`,
        priority: 3,
      };
    }
  }

  // Daily plan
  if (records.length > 0) {
    return {
      type: 'daily_plan',
      message: `${name}，今天继续学习？我已经准备好了。`,
      priority: 1,
    };
  }

  return null;
}
