// Four-dimensional growth tracking
import { db } from '../db/client.js';
import { progress, growthSnapshots } from '../db/schema.js';
import { eq } from 'drizzle-orm';

export interface GrowthInsights {
  weakTopics: string[];
  predictions: string[];
  emotionalPatterns: string[];
  suggestions: string[];
}

export async function computeGrowthInsights(userId: string): Promise<GrowthInsights> {
  const records = await db.select().from(progress).where(eq(progress.userId, userId));

  if (records.length === 0) {
    return {
      weakTopics: [],
      predictions: [],
      emotionalPatterns: [],
      suggestions: ['开始做题，知芽会逐步了解你的学习模式。'],
    };
  }

  // Find weak knowledge points (low accuracy)
  const kpStats: Record<string, { correct: number; total: number; kpId: string }> = {};
  for (const r of records) {
    const key = `${r.paperId}:${r.kpId}`;
    if (!kpStats[key]) kpStats[key] = { correct: 0, total: 0, kpId: r.kpId };
    kpStats[key].total++;
    if (r.correct) kpStats[key].correct++;
  }

  const weakTopics = Object.entries(kpStats)
    .filter(([, stats]) => stats.total >= 3 && stats.correct / stats.total < 0.5)
    .map(([key]) => key);

  const suggestions: string[] = [];
  if (weakTopics.length > 0) {
    suggestions.push(`有${weakTopics.length}个薄弱知识点需要关注`);
  }

  const accuracy = records.filter((r) => r.correct).length / records.length;
  if (accuracy < 0.6) {
    suggestions.push('正确率偏低，建议放慢节奏，确保每个知识点掌握后再前进');
  } else if (accuracy > 0.85) {
    suggestions.push('正确率很高！可以尝试更有挑战性的题目');
  }

  return {
    weakTopics,
    predictions: [],
    emotionalPatterns: [],
    suggestions,
  };
}

export async function getGrowthTreeData(userId: string) {
  const records = await db.select().from(progress).where(eq(progress.userId, userId));

  // Build tree from progress data
  const kpMastery: Record<string, { correct: number; total: number; title: string }> = {};
  for (const r of records) {
    const key = r.kpId;
    if (!kpMastery[key]) kpMastery[key] = { correct: 0, total: 0, title: r.kpId };
    kpMastery[key].total++;
    if (r.correct) kpMastery[key].correct++;
  }

  const leaves = Object.entries(kpMastery).map(([kpId, stats]) => {
    const rate = stats.total > 0 ? stats.correct / stats.total : 0;
    return {
      knowledgePointId: kpId,
      title: stats.title,
      growth: rate >= 0.9 ? 'full' : rate >= 0.5 ? 'half' : 'sprout',
    };
  });

  return {
    trunk: { thickness: Math.min(5, 1 + leaves.length * 0.05) },
    branches: [
      { dimension: 'academic', length: Math.min(1, leaves.length * 0.03), leafCount: leaves.length },
      { dimension: 'metacognitive', length: 0.1, leafCount: 0 },
      { dimension: 'emotional', length: 0.1, leafCount: 0 },
      { dimension: 'lifeExploration', length: 0.1, leafCount: 0 },
    ],
    leaves,
    flowers: [],
    rings: 0,
  };
}
