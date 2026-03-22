// Layer 4: AI Agent Engine - MiniMax + Claude + Synapse routing with streaming

export interface AIRequest {
  messages: { role: string; content: string }[];
  systemPrompt: string;
  stream?: boolean;
  temperature?: number;
  userId?: string;
  sessionId?: string;
}

export async function streamAIResponse(req: AIRequest): Promise<ReadableStream> {
  const synapseUrl = process.env.SYNAPSE_URL;
  const minimaxKey = process.env.MINIMAX_API_KEY;
  const claudeKey = process.env.ANTHROPIC_API_KEY;

  // Priority: Synapse > Claude > MiniMax
  if (synapseUrl) {
    return streamSynapse(req, synapseUrl);
  }
  if (claudeKey) {
    return streamClaude(req, claudeKey);
  }
  if (minimaxKey) {
    return streamMiniMax(req, minimaxKey);
  }

  throw new Error('No AI API key configured. Set SYNAPSE_URL, MINIMAX_API_KEY, or ANTHROPIC_API_KEY.');
}

async function streamMiniMax(req: AIRequest, apiKey: string): Promise<ReadableStream> {
  const url = 'https://api.minimax.chat/v1/text/chatcompletion_v2';

  const body = {
    model: 'MiniMax-M2.5',
    messages: [
      { role: 'system', content: req.systemPrompt },
      ...req.messages,
    ],
    stream: true,
    temperature: req.temperature ?? 0.7,
    max_tokens: 20480,
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
  });

  if (!response.ok || !response.body) {
    throw new Error(`MiniMax API error: ${response.status}`);
  }

  return response.body;
}

async function streamClaude(req: AIRequest, apiKey: string): Promise<ReadableStream> {
  const url = 'https://api.anthropic.com/v1/messages';

  const body = {
    model: 'claude-sonnet-4-6',
    max_tokens: 8192,
    system: req.systemPrompt,
    messages: req.messages.map((m) => ({
      role: m.role === 'assistant' ? 'assistant' : 'user',
      content: m.content,
    })),
    stream: true,
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify(body),
  });

  if (!response.ok || !response.body) {
    throw new Error(`Claude API error: ${response.status}`);
  }

  // Transform Claude SSE format to OpenAI-compatible format
  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  return new ReadableStream({
    async start(controller) {
      const encoder = new TextEncoder();
      let buffer = '';

      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split('\n');
          buffer = lines.pop() || '';

          for (const line of lines) {
            if (line.startsWith('data: ')) {
              const data = line.slice(6);
              if (data === '[DONE]') continue;

              try {
                const parsed = JSON.parse(data);
                if (parsed.type === 'content_block_delta' && parsed.delta?.text) {
                  const chunk = {
                    choices: [{ delta: { content: parsed.delta.text } }],
                  };
                  controller.enqueue(
                    encoder.encode(`data: ${JSON.stringify(chunk)}\n\n`)
                  );
                }
              } catch {
                // skip malformed
              }
            }
          }
        }
        controller.enqueue(encoder.encode('data: [DONE]\n\n'));
        controller.close();
      } catch (err) {
        controller.error(err);
      }
    },
  });
}

// Synapse Agent API — delegates to Synapse for full agent capabilities
async function streamSynapse(req: AIRequest, synapseUrl: string): Promise<ReadableStream> {
  const lastMessage = req.messages[req.messages.length - 1];

  const response = await fetch(`${synapseUrl}/api/agent`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      persona: 'zhiya',
      userId: req.userId || 'default',
      sessionId: req.sessionId || 'default',
      message: lastMessage?.content || '',
      context: { systemPrompt: req.systemPrompt },
      stream: true,
    }),
  });

  if (!response.ok || !response.body) {
    throw new Error(`Synapse API error: ${response.status}`);
  }

  // Transform Synapse SSE events to OpenAI-compatible format for the iOS client
  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  return new ReadableStream({
    async start(controller) {
      const encoder = new TextEncoder();
      let buffer = '';

      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split('\n');
          buffer = lines.pop() || '';

          for (const line of lines) {
            if (line.startsWith('data: ')) {
              const data = line.slice(6);
              if (data === '[DONE]') continue;

              try {
                const parsed = JSON.parse(data);

                // Handle different Synapse event types
                if (parsed.type === 'text' || parsed.type === 'content_block_delta') {
                  const text = parsed.text || parsed.delta?.text || '';
                  if (text) {
                    const chunk = { choices: [{ delta: { content: text } }] };
                    controller.enqueue(encoder.encode(`data: ${JSON.stringify(chunk)}\n\n`));
                  }
                } else if (parsed.type === 'tool_call') {
                  // Forward tool_call events as special SSE events for the iOS client
                  controller.enqueue(encoder.encode(`data: ${JSON.stringify(parsed)}\n\n`));
                } else if (parsed.type === 'tool_result') {
                  controller.enqueue(encoder.encode(`data: ${JSON.stringify(parsed)}\n\n`));
                }
              } catch {
                // skip malformed JSON
              }
            }
          }
        }
        controller.enqueue(encoder.encode('data: [DONE]\n\n'));
        controller.close();
      } catch (err) {
        controller.error(err);
      }
    },
  });
}

// Non-streaming fallback
export async function callAI(req: AIRequest): Promise<string> {
  const minimaxKey = process.env.MINIMAX_API_KEY;

  if (!minimaxKey) {
    throw new Error('No AI API key configured');
  }

  const url = 'https://api.minimax.chat/v1/text/chatcompletion_v2';
  const body = {
    model: 'MiniMax-M2.5',
    messages: [
      { role: 'system', content: req.systemPrompt },
      ...req.messages,
    ],
    stream: false,
    temperature: req.temperature ?? 0.7,
    max_tokens: 20480,
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${minimaxKey}`,
    },
    body: JSON.stringify(body),
  });

  const result = (await response.json()) as any;
  return result.choices?.[0]?.message?.content || '';
}
