import { Hono } from 'hono';
import { streamSSE } from 'hono/streaming';
import { streamAIResponse } from '../services/aiGateway.js';
import { preHookCheck } from '../services/complianceEngine.js';
import { TUTOR_SYSTEM_PROMPT, SOLVER_SYSTEM_PROMPT } from '../prompts/zhiyaPersona.js';

const chat = new Hono();

chat.post('/tutor', async (c) => {
  const body = await c.req.json();
  const { sessionId, message, context } = body;

  if (!message) {
    return c.json({ error: 'message is required' }, 400);
  }

  // Pre-hook: emotional check
  const preCheck = preHookCheck(message);

  const systemPrompt = TUTOR_SYSTEM_PROMPT({
    question: context?.question,
    options: context?.options,
    correctAnswer: context?.correctAnswer,
    explanation: context?.explanation,
    kpTitle: context?.kpTitle,
    studentAnswer: context?.studentAnswer,
  });

  try {
    const stream = await streamAIResponse({
      messages: [{ role: 'user', content: message }],
      systemPrompt: preCheck.shouldIntervene
        ? systemPrompt + `\n\n注意：${preCheck.suggestion}`
        : systemPrompt,
      stream: true,
    });

    // Forward SSE stream
    return new Response(stream, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
      },
    });
  } catch (err) {
    return c.json({ error: 'AI service error', detail: String(err) }, 500);
  }
});

chat.post('/solve', async (c) => {
  const body = await c.req.json();
  const { sessionId, problemText } = body;

  if (!problemText) {
    return c.json({ error: 'problemText is required' }, 400);
  }

  try {
    const stream = await streamAIResponse({
      messages: [{ role: 'user', content: `请解答这道题：\n\n${problemText}` }],
      systemPrompt: SOLVER_SYSTEM_PROMPT,
      stream: true,
    });

    return new Response(stream, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
      },
    });
  } catch (err) {
    return c.json({ error: 'AI service error', detail: String(err) }, 500);
  }
});

export default chat;
