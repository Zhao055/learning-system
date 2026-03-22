import { Context, Next } from 'hono';

// Layer 5: Compliance middleware - ensures Zhiya's character traits
export async function complianceMiddleware(c: Context, next: Next) {
  // Pre-hook: check user message for concerning content
  if (c.req.method === 'POST') {
    try {
      const body = await c.req.json();
      const message = body.message || '';

      // Check for distress signals
      if (containsDistressSignals(message)) {
        c.set('emotionalMode', 'caring');
        c.set('prioritizeWellbeing', true);
      }
    } catch {
      // Not JSON body, continue normally
    }
  }

  await next();
}

function containsDistressSignals(text: string): boolean {
  const signals = [
    '不想学了', '太难了', '受不了', '好烦', '焦虑',
    '压力大', '很累', '不开心', '讨厌', '放弃',
    '做不到', '没用', '害怕', '紧张',
  ];
  const lower = text.toLowerCase();
  return signals.some((s) => lower.includes(s));
}
