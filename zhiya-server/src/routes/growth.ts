import { Hono } from 'hono';
import { getGrowthTreeData, computeGrowthInsights } from '../services/growthTracker.js';
import { getMemories, getMilestones, getGrowthTrajectory } from '../services/memoryService.js';
import { generateInsights } from '../services/decisionEngine.js';

const growth = new Hono();

growth.get('/tree', async (c) => {
  const userId = c.get('userId') as string;
  const tree = await getGrowthTreeData(userId);
  return c.json(tree);
});

growth.get('/memories', async (c) => {
  const userId = c.get('userId') as string;
  const type = c.req.query('type');
  const mems = await getMemories(userId, type);
  return c.json(mems);
});

growth.get('/insights', async (c) => {
  const userId = c.get('userId') as string;
  const insights = await generateInsights(userId);
  return c.json(insights);
});

growth.get('/trajectory', async (c) => {
  const userId = c.get('userId') as string;
  const trajectory = await getGrowthTrajectory(userId);
  return c.json(trajectory);
});

growth.get('/profile', async (c) => {
  const userId = c.get('userId') as string;

  const [tree, mems, milestoneList, trajectory, insights] = await Promise.all([
    getGrowthTreeData(userId),
    getMemories(userId),
    getMilestones(userId),
    getGrowthTrajectory(userId),
    computeGrowthInsights(userId),
  ]);

  return c.json({
    growthTree: tree,
    memories: mems,
    milestones: milestoneList,
    trajectory,
    insights,
  });
});

export default growth;
