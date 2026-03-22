// Layer 7: Personal Memory - Four-dimensional data accumulation
import { db } from '../db/client.js';
import { memories, milestones, companionState, growthSnapshots } from '../db/schema.js';
import { eq, and } from 'drizzle-orm';
import { v4 as uuid } from 'uuid';

export async function addMemory(
  userId: string,
  data: { type: string; title: string; content: string; dimension?: string; emotionalWeight?: number }
) {
  const id = uuid();
  await db.insert(memories).values({
    id,
    userId,
    type: data.type,
    title: data.title,
    content: data.content,
    dimension: data.dimension,
    emotionalWeight: data.emotionalWeight ?? 0.5,
    timestamp: new Date().toISOString(),
  });
  return id;
}

export async function getMemories(userId: string, type?: string) {
  if (type) {
    return db.select().from(memories).where(and(eq(memories.userId, userId), eq(memories.type, type)));
  }
  return db.select().from(memories).where(eq(memories.userId, userId));
}

export async function addMilestone(
  userId: string,
  data: { title: string; description: string; type: string }
) {
  const id = uuid();
  await db.insert(milestones).values({
    id,
    userId,
    title: data.title,
    description: data.description,
    type: data.type,
    achievedDate: new Date().toISOString(),
  });
  return id;
}

export async function getMilestones(userId: string) {
  return db.select().from(milestones).where(eq(milestones.userId, userId));
}

export async function addGrowthSnapshot(
  userId: string,
  data: { dimension: string; score: number; details?: string }
) {
  const id = uuid();
  await db.insert(growthSnapshots).values({
    id,
    userId,
    dimension: data.dimension,
    score: data.score,
    details: data.details,
    date: new Date().toISOString(),
  });
  return id;
}

export async function getGrowthTrajectory(userId: string) {
  const snapshots = await db
    .select()
    .from(growthSnapshots)
    .where(eq(growthSnapshots.userId, userId));

  const grouped: Record<string, typeof snapshots> = {};
  for (const s of snapshots) {
    if (!grouped[s.dimension]) grouped[s.dimension] = [];
    grouped[s.dimension].push(s);
  }
  return grouped;
}

export async function getOrCreateCompanionState(userId: string) {
  const existing = await db
    .select()
    .from(companionState)
    .where(eq(companionState.userId, userId));

  if (existing.length > 0) return existing[0];

  const id = uuid();
  const initial = {
    id,
    userId,
    emotionalProfile: JSON.stringify({ moodBaseline: 'neutral', recentMoods: [] }),
    growthTree: JSON.stringify({ trunkThickness: 1, branches: [], leaves: [], flowers: [], rings: 0 }),
    weeklyLetters: JSON.stringify([]),
    lastActiveAt: new Date().toISOString(),
  };

  await db.insert(companionState).values(initial);
  return initial;
}
