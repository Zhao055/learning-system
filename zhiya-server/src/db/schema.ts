import { sqliteTable, text, integer, real } from 'drizzle-orm/sqlite-core';

export const users = sqliteTable('users', {
  id: text('id').primaryKey(),
  deviceId: text('device_id').notNull().unique(),
  name: text('name'),
  subjects: text('subjects'), // JSON array
  goals: text('goals'),
  joinDate: text('join_date').notNull(),
  examDate: text('exam_date'),
  treeLevel: integer('tree_level').default(1),
  relationshipStage: text('relationship_stage').default('seed'),
  createdAt: text('created_at').notNull(),
});

export const progress = sqliteTable('progress', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull().references(() => users.id),
  paperId: text('paper_id').notNull(),
  chapterId: text('chapter_id').notNull(),
  kpId: text('kp_id').notNull(),
  questionId: text('question_id').notNull(),
  correct: integer('correct', { mode: 'boolean' }).notNull(),
  selectedIndex: integer('selected_index').notNull(),
  timestamp: text('timestamp').notNull(),
});

export const sessions = sqliteTable('sessions', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull().references(() => users.id),
  type: text('type').notNull(), // 'tutor' | 'solver'
  context: text('context'), // JSON
  messages: text('messages'), // JSON array
  createdAt: text('created_at').notNull(),
  updatedAt: text('updated_at').notNull(),
});

export const memories = sqliteTable('memories', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull().references(() => users.id),
  type: text('type').notNull(), // memory type
  title: text('title').notNull(),
  content: text('content').notNull(),
  dimension: text('dimension'), // growth dimension
  emotionalWeight: real('emotional_weight').default(0.5),
  timestamp: text('timestamp').notNull(),
});

export const milestones = sqliteTable('milestones', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull().references(() => users.id),
  title: text('title').notNull(),
  description: text('description').notNull(),
  type: text('type').notNull(),
  achievedDate: text('achieved_date').notNull(),
  celebrationShown: integer('celebration_shown', { mode: 'boolean' }).default(false),
});

export const companionState = sqliteTable('companion_state', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull().references(() => users.id).unique(),
  emotionalProfile: text('emotional_profile'), // JSON
  growthTree: text('growth_tree'), // JSON
  weeklyLetters: text('weekly_letters'), // JSON array
  lastGreeting: text('last_greeting'),
  lastActiveAt: text('last_active_at'),
});

export const growthSnapshots = sqliteTable('growth_snapshots', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull().references(() => users.id),
  dimension: text('dimension').notNull(),
  score: real('score').notNull(),
  details: text('details'),
  date: text('date').notNull(),
});
