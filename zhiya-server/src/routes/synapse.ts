import { Hono } from 'hono';
import { streamSSE } from 'hono/streaming';

const SYNAPSE_URL = process.env.SYNAPSE_URL || '';
const SYNAPSE_PERSONA = 'zhiya';

const synapse = new Hono();

// POST /chat — Forward chat to Synapse Agent API with SSE streaming
synapse.post('/chat', async (c) => {
  if (!SYNAPSE_URL) {
    return c.json({ error: 'SYNAPSE_URL not configured' }, 503);
  }

  const userId = c.get('userId') as string;
  const body = await c.req.json();
  const { message, sessionId, context } = body;

  if (!message) {
    return c.json({ error: 'message is required' }, 400);
  }

  // Forward to Synapse Agent API
  const response = await fetch(`${SYNAPSE_URL}/api/agent`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      persona: SYNAPSE_PERSONA,
      userId,
      sessionId: sessionId || `zhiya-${userId}`,
      message,
      context: context || {},
      stream: true,
    }),
  });

  if (!response.ok || !response.body) {
    const errorText = await response.text().catch(() => 'Unknown error');
    return c.json({ error: `Synapse error: ${response.status} ${errorText}` }, 502);
  }

  // Stream the SSE response back to the iOS client
  // Synapse returns events: text, tool_call, tool_result, done
  c.header('Content-Type', 'text/event-stream');
  c.header('Cache-Control', 'no-cache');
  c.header('Connection', 'keep-alive');

  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  const stream = new ReadableStream({
    async start(controller) {
      const encoder = new TextEncoder();
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          // Pass through SSE events from Synapse
          controller.enqueue(value);
        }
        controller.close();
      } catch (err) {
        controller.error(err);
      }
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
});

// GET /memories — Get user's memories from Synapse
synapse.get('/memories', async (c) => {
  if (!SYNAPSE_URL) {
    return c.json({ error: 'SYNAPSE_URL not configured' }, 503);
  }

  const userId = c.get('userId') as string;
  const type = c.req.query('type') || 'facts';

  const response = await fetch(
    `${SYNAPSE_URL}/api/memory/${SYNAPSE_PERSONA}/${userId}?type=${type}`,
    { headers: { 'Content-Type': 'application/json' } },
  );

  if (!response.ok) {
    return c.json({ error: 'Failed to fetch memories' }, 502);
  }

  const data = await response.json();
  return c.json(data);
});

// GET /notifications — Get pending proactive messages from Synapse
synapse.get('/notifications', async (c) => {
  if (!SYNAPSE_URL) {
    return c.json({ error: 'SYNAPSE_URL not configured' }, 503);
  }

  const userId = c.get('userId') as string;
  const since = c.req.query('since') || new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  const response = await fetch(
    `${SYNAPSE_URL}/api/proactive/${SYNAPSE_PERSONA}/${userId}/pending?since=${since}`,
    { headers: { 'Content-Type': 'application/json' } },
  );

  if (!response.ok) {
    // Return empty array if proactive service is unavailable
    return c.json({ notifications: [] });
  }

  const data = await response.json();
  return c.json(data);
});

// POST /challenge/answer — Record answer and sync to Synapse memory
synapse.post('/challenge/answer', async (c) => {
  const userId = c.get('userId') as string;
  const body = await c.req.json();
  const { paperId, chapterId, kpId, questionId, correct, selectedIndex, kpTitle } = body;

  if (!paperId || !questionId || correct === undefined) {
    return c.json({ error: 'Missing required fields' }, 400);
  }

  // 1. Record in local progress database
  const { db } = await import('../db/client.js');
  const { progress } = await import('../db/schema.js');
  const { v4: uuid } = await import('uuid');

  await db.insert(progress).values({
    id: uuid(),
    userId,
    paperId,
    chapterId,
    kpId,
    questionId,
    correct,
    selectedIndex: selectedIndex ?? 0,
    timestamp: new Date().toISOString(),
  });

  // 2. If Synapse is configured, write to memory
  if (SYNAPSE_URL) {
    try {
      await fetch(`${SYNAPSE_URL}/api/agent`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          persona: SYNAPSE_PERSONA,
          userId,
          sessionId: `zhiya-${userId}-system`,
          message: `[SYSTEM] Student ${correct ? 'correctly' : 'incorrectly'} answered a question on "${kpTitle || kpId}". ${correct ? 'Record this achievement.' : 'Note this for future review.'}`,
          context: { isSystemEvent: true },
          stream: false,
        }),
      });
    } catch {
      // Non-blocking: don't fail the answer recording if Synapse is down
    }
  }

  return c.json({ success: true });
});

export default synapse;
