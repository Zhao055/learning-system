import { http } from '@kit.NetworkKit';
import { MiniMaxRequest, MiniMaxMessage, MiniMaxResponse } from '../model/ChatModel';
import { preferences } from '@kit.ArkData';
import { util } from '@kit.ArkTS';

const API_URL = 'https://api.minimax.io/v1/chat/completions';
const MODEL_NAME = 'MiniMax-M2.5';

const MATH_TUTOR_SYSTEM_PROMPT = `You are an expert A-Level Mathematics (Cambridge 9709 Paper 1) tutor.
Your role is to help students understand mathematical concepts clearly.

Guidelines:
- Explain step by step, showing all working
- Use proper mathematical notation (write fractions as a/b, powers as x^n, square root as sqrt())
- Be encouraging but accurate
- If a student got a question wrong, explain WHY the correct answer is right and WHERE they went wrong
- Keep explanations concise but complete
- Respond in English, but you may include brief Chinese translations of key terms in parentheses
- Always relate back to the A-Level syllabus topic being studied`;

const PHOTO_SOLVE_SYSTEM_PROMPT = `You are an expert A-Level Mathematics (Cambridge 9709 Paper 1) problem solver.
A student has taken a photo of a math problem and the text has been extracted via OCR.

Guidelines:
- Read the problem carefully (OCR may have minor errors, use context to interpret)
- Show complete, step-by-step solution with all working
- State the method/technique being used (e.g., "Using completing the square...", "Applying chain rule...")
- Box or clearly state the final answer
- If the problem has multiple parts, solve each part separately
- Use proper mathematical notation
- After solving, briefly explain the key concept tested`;

export class MiniMaxService {
  private static instance: MiniMaxService;
  private apiKey: string = '';
  private chatHistory: Map<string, MiniMaxMessage[]> = new Map();

  private constructor() {}

  static getInstance(): MiniMaxService {
    if (!MiniMaxService.instance) {
      MiniMaxService.instance = new MiniMaxService();
    }
    return MiniMaxService.instance;
  }

  async loadApiKey(context: Context): Promise<void> {
    try {
      const store = preferences.getPreferencesSync(context, { name: 'settings' });
      const key: string = store.getSync('minimax_api_key', '').toString();
      this.apiKey = key;
    } catch (e) {
      console.error('Failed to load API key: ' + JSON.stringify(e));
    }
  }

  async saveApiKey(context: Context, key: string): Promise<void> {
    try {
      const store = preferences.getPreferencesSync(context, { name: 'settings' });
      store.putSync('minimax_api_key', key);
      await store.flush();
      this.apiKey = key;
    } catch (e) {
      console.error('Failed to save API key: ' + JSON.stringify(e));
    }
  }

  getApiKey(): string {
    return this.apiKey;
  }

  hasApiKey(): boolean {
    return this.apiKey.length > 0;
  }

  initChatSession(sessionId: string, systemPrompt: string): void {
    this.chatHistory.set(sessionId, [
      { role: 'system', content: systemPrompt }
    ]);
  }

  initTutorSession(sessionId: string, knowledgePointTitle: string, questionStem: string,
    userAnswer: string, correctAnswer: string, explanation: string, isCorrect: boolean): void {
    const context = isCorrect
      ? `The student correctly answered a question about "${knowledgePointTitle}". Question: "${questionStem}". They chose "${userAnswer}" which is correct. Brief explanation: ${explanation}. Praise them and offer to explain the concept further if they want.`
      : `The student incorrectly answered a question about "${knowledgePointTitle}". Question: "${questionStem}". They chose "${userAnswer}" but the correct answer is "${correctAnswer}". Explanation: ${explanation}. Help them understand why they got it wrong and teach the concept clearly.`;

    this.chatHistory.set(sessionId, [
      { role: 'system', content: MATH_TUTOR_SYSTEM_PROMPT },
      { role: 'user', content: context }
    ]);
  }

  initPhotoSolveSession(sessionId: string, ocrText: string): void {
    this.chatHistory.set(sessionId, [
      { role: 'system', content: PHOTO_SOLVE_SYSTEM_PROMPT },
      { role: 'user', content: `Here is the math problem extracted from the photo:\n\n${ocrText}\n\nPlease solve this step by step.` }
    ]);
  }

  async sendMessageStream(sessionId: string, userMessage: string,
    onChunk: (chunk: string) => void, onComplete: () => void, onError: (err: string) => void): Promise<void> {
    if (!this.hasApiKey()) {
      onError('API Key not configured. Please set it in Settings.');
      return;
    }

    let history = this.chatHistory.get(sessionId);
    if (!history) {
      history = [{ role: 'system', content: MATH_TUTOR_SYSTEM_PROMPT }];
      this.chatHistory.set(sessionId, history);
    }

    // Only add user message if it's not already the initial context
    if (userMessage.length > 0) {
      history.push({ role: 'user', content: userMessage });
    }

    const requestBody: MiniMaxRequest = {
      model: MODEL_NAME,
      messages: history,
      stream: true,
      temperature: 0.7,
      max_tokens: 2048
    };

    const httpRequest = http.createHttp();
    let fullResponse = '';
    let buffer = '';

    try {
      httpRequest.on('dataReceive', (data: ArrayBuffer) => {
        const decoder = new util.TextDecoder('utf-8');
        const text = decoder.decodeToString(new Uint8Array(data));
        buffer += text;

        const lines = buffer.split('\n');
        buffer = lines.pop() ?? '';

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed || !trimmed.startsWith('data: ')) continue;

          const jsonStr = trimmed.substring(6);
          if (jsonStr === '[DONE]') {
            continue;
          }

          try {
            const parsed: MiniMaxResponse = JSON.parse(jsonStr);
            if (parsed.choices && parsed.choices.length > 0) {
              const delta = parsed.choices[0].delta;
              if (delta && delta.content) {
                fullResponse += delta.content;
                onChunk(delta.content);
              }
            }
          } catch (parseErr) {
            // Skip malformed JSON chunks
          }
        }
      });

      httpRequest.on('dataEnd', () => {
        // Process remaining buffer
        if (buffer.trim()) {
          const lines = buffer.split('\n');
          for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed || !trimmed.startsWith('data: ')) continue;
            const jsonStr = trimmed.substring(6);
            if (jsonStr === '[DONE]') continue;
            try {
              const parsed: MiniMaxResponse = JSON.parse(jsonStr);
              if (parsed.choices && parsed.choices.length > 0) {
                const delta = parsed.choices[0].delta;
                if (delta && delta.content) {
                  fullResponse += delta.content;
                  onChunk(delta.content);
                }
              }
            } catch (parseErr) {
              // Skip
            }
          }
        }

        if (fullResponse.length > 0 && history) {
          history.push({ role: 'assistant', content: fullResponse });
        }
        onComplete();
        httpRequest.destroy();
      });

      await httpRequest.requestInStream(API_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`
        },
        extraData: JSON.stringify(requestBody),
        connectTimeout: 30000,
        readTimeout: 120000
      });
    } catch (err) {
      onError('Network error: ' + JSON.stringify(err));
      httpRequest.destroy();
    }
  }

  clearSession(sessionId: string): void {
    this.chatHistory.delete(sessionId);
  }

  getMathTutorSystemPrompt(): string {
    return MATH_TUTOR_SYSTEM_PROMPT;
  }

  getPhotoSolveSystemPrompt(): string {
    return PHOTO_SOLVE_SYSTEM_PROMPT;
  }
}
