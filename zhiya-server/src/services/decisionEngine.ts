// Layer 6.5: Decision Engine - predictions and insights
import { db } from '../db/client.js';
import { progress } from '../db/schema.js';
import { eq } from 'drizzle-orm';

export interface DecisionInsight {
  type: 'weak_prediction' | 'pattern' | 'recommendation';
  content: string;
  confidence: number;
  data?: Record<string, unknown>;
}

export async function generateInsights(userId: string): Promise<DecisionInsight[]> {
  const records = await db.select().from(progress).where(eq(progress.userId, userId));
  const insights: DecisionInsight[] = [];

  if (records.length < 10) {
    return [{
      type: 'recommendation',
      content: '做更多题目，知芽会更好地了解你的学习模式。',
      confidence: 1.0,
    }];
  }

  // Analyze error patterns
  const kpErrors: Record<string, number> = {};
  for (const r of records) {
    if (!r.correct) {
      kpErrors[r.kpId] = (kpErrors[r.kpId] || 0) + 1;
    }
  }

  // Find top weak areas
  const topWeak = Object.entries(kpErrors)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3);

  for (const [kpId, errorCount] of topWeak) {
    insights.push({
      type: 'weak_prediction',
      content: `知识点 ${kpId} 错了${errorCount}次，建议重点复习`,
      confidence: Math.min(0.9, errorCount * 0.15),
      data: { kpId, errorCount },
    });
  }

  // Time pattern analysis
  const hourBuckets: Record<number, { correct: number; total: number }> = {};
  for (const r of records) {
    const hour = new Date(r.timestamp).getHours();
    if (!hourBuckets[hour]) hourBuckets[hour] = { correct: 0, total: 0 };
    hourBuckets[hour].total++;
    if (r.correct) hourBuckets[hour].correct++;
  }

  let bestHour = -1;
  let bestRate = 0;
  for (const [hour, stats] of Object.entries(hourBuckets)) {
    if (stats.total >= 5) {
      const rate = stats.correct / stats.total;
      if (rate > bestRate) {
        bestRate = rate;
        bestHour = parseInt(hour);
      }
    }
  }

  if (bestHour >= 0) {
    insights.push({
      type: 'pattern',
      content: `你在${bestHour}点左右学习效率最高（正确率${Math.round(bestRate * 100)}%）`,
      confidence: 0.7,
      data: { bestHour, accuracy: bestRate },
    });
  }

  return insights;
}
