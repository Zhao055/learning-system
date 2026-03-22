// Companion intelligence: greetings, relationship stage, weekly letters, proactive caring
import { db } from '../db/client.js';
import { users, progress } from '../db/schema.js';
import { eq, count } from 'drizzle-orm';

export interface GreetingResult {
  message: string;
  emotion: string;
  suggestion?: string;
  context: string;
}

export async function generateGreeting(userId: string): Promise<GreetingResult> {
  const user = await db.select().from(users).where(eq(users.id, userId));
  if (!user.length) {
    return { message: '你好！', emotion: 'gazing', context: 'new_user' };
  }

  const u = user[0];
  const name = u.name || '同学';
  const joinDate = new Date(u.joinDate);
  const daysSince = Math.floor((Date.now() - joinDate.getTime()) / 86400000);
  const hour = new Date().getHours();

  // Late night
  if (hour >= 22) {
    return {
      message: `已经很晚了，${name}。今天学够多了，早点休息吧。`,
      emotion: 'caring',
      context: 'late_night',
    };
  }

  // Exam day check
  if (u.examDate) {
    const examDate = new Date(u.examDate);
    const daysToExam = Math.ceil((examDate.getTime() - Date.now()) / 86400000);
    if (daysToExam === 0) {
      return {
        message: `今天考试？${name}，你准备了很多。去吧，考完来告诉我。`,
        emotion: 'calm',
        context: 'exam_day',
      };
    }
    if (daysToExam > 0 && daysToExam <= 7) {
      return {
        message: `还有${daysToExam}天考试。一步一步来，你可以的。`,
        emotion: 'gazing',
        suggestion: '专注薄弱知识点',
        context: 'exam_countdown',
      };
    }
  }

  // Get progress stats
  const progressRecords = await db.select().from(progress).where(eq(progress.userId, userId));
  const totalAnswered = progressRecords.length;
  const totalCorrect = progressRecords.filter((r) => r.correct).length;
  const accuracy = totalAnswered > 0 ? Math.round((totalCorrect / totalAnswered) * 100) : 0;

  // Stage-based greeting
  const stage = daysSince <= 7 ? 'seed' : daysSince <= 30 ? 'familiar' : daysSince <= 90 ? 'understanding' : 'companion';

  switch (stage) {
    case 'seed': {
      const timeGreeting = hour < 12 ? '早上好' : hour < 18 ? '下午好' : '晚上好';
      return {
        message: `${timeGreeting}，${name}！今天想学点什么？`,
        emotion: 'gazing',
        context: 'seed_greeting',
      };
    }
    case 'familiar':
      return {
        message: totalAnswered > 0
          ? `${name}，你已经做了${totalAnswered}道题了，正确率${accuracy}%。继续加油！`
          : `又见面了，${name}！准备好了吗？`,
        emotion: 'happy',
        context: 'familiar_greeting',
      };
    case 'understanding':
      return {
        message: `${name}，今天状态怎么样？`,
        emotion: 'happy',
        suggestion: totalAnswered > 0 ? `正确率${accuracy}%，保持住！` : undefined,
        context: 'understanding_greeting',
      };
    case 'companion':
      return {
        message: `${name}，我们已经一起走过${daysSince}天了。今天想做什么？`,
        emotion: 'happy',
        context: 'companion_greeting',
      };
  }
}

export function getRelationshipStage(daysSinceJoin: number) {
  if (daysSinceJoin <= 7) return { stage: 'seed', label: '初识' };
  if (daysSinceJoin <= 30) return { stage: 'familiar', label: '熟悉' };
  if (daysSinceJoin <= 90) return { stage: 'understanding', label: '了解' };
  return { stage: 'companion', label: '同行' };
}
