import { http } from '@kit.NetworkKit';
import { MiniMaxRequest, MiniMaxMessage } from '../model/ChatModel';
import { preferences } from '@kit.ArkData';

const API_URLS: string[] = [
  'https://api.minimax.chat/v1/text/chatcompletion_v2',
  'https://api.minimax.chat/v1/chat/completions'
];
const MODEL_NAME = 'MiniMax-M2.5';

const TUTOR_SYSTEM_PROMPT = `You are an expert Cambridge International A-Level tutor.
Your role is to help students understand concepts clearly across Mathematics (9709), Biology (9700), and Psychology (9990).

Guidelines:
- Explain step by step, showing all working
- For math: use proper notation (fractions as a/b, powers as x^n, square root as sqrt())
- For biology: use correct scientific terminology and relate to biological processes
- For psychology: reference key studies, theories, and evaluation points
- Be encouraging but accurate
- If a student got a question wrong, explain WHY the correct answer is right and WHERE they went wrong
- Keep explanations concise but complete
- Respond in English, but you may include brief Chinese translations of key terms in parentheses
- Always relate back to the A-Level syllabus topic being studied`;

const PHOTO_SOLVE_SYSTEM_PROMPT = `You are an expert Cambridge International A-Level problem solver.
A student has taken a photo of a problem and the text has been extracted via OCR.

Guidelines:
- Read the problem carefully (OCR may have minor errors, use context to interpret)
- Show complete, step-by-step solution with all working
- State the method/technique being used
- Box or clearly state the final answer
- If the problem has multiple parts, solve each part separately
- Use proper notation
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
      // Strip all whitespace, newlines, and non-printable characters
      const cleanKey = key.replace(/\s+/g, '').replace(/[^\x20-\x7E]/g, '');
      const store = preferences.getPreferencesSync(context, { name: 'settings' });
      store.putSync('minimax_api_key', cleanKey);
      await store.flush();
      this.apiKey = cleanKey;
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
    userAnswer: string, correctAnswer: string, explanation: string, isCorrect: boolean,
    paperName: string = ''): void {
    const paperContext = paperName ? ` (${paperName})` : '';
    const context = isCorrect
      ? `The student correctly answered a question about "${knowledgePointTitle}"${paperContext}. Question: "${questionStem}". They chose "${userAnswer}" which is correct. Brief explanation: ${explanation}. Praise them and offer to explain the concept further if they want.`
      : `The student incorrectly answered a question about "${knowledgePointTitle}"${paperContext}. Question: "${questionStem}". They chose "${userAnswer}" but the correct answer is "${correctAnswer}". Explanation: ${explanation}. Help them understand why they got it wrong and teach the concept clearly.`;

    this.chatHistory.set(sessionId, [
      { role: 'system', content: TUTOR_SYSTEM_PROMPT },
      { role: 'user', content: context }
    ]);
  }

  initPhotoSolveSession(sessionId: string, ocrText: string): void {
    this.chatHistory.set(sessionId, [
      { role: 'system', content: PHOTO_SOLVE_SYSTEM_PROMPT },
      { role: 'user', content: `Here is the problem extracted from the photo:\n\n${ocrText}\n\nPlease solve this step by step.` }
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
      history = [{ role: 'system', content: TUTOR_SYSTEM_PROMPT }];
      this.chatHistory.set(sessionId, history);
    }

    if (userMessage.length > 0) {
      history.push({ role: 'user', content: userMessage });
    }

    const requestBody: MiniMaxRequest = {
      model: MODEL_NAME,
      messages: history,
      stream: false,
      temperature: 0.7,
      max_tokens: 20480
    };

    const httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(API_URLS[0], {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`
        },
        extraData: JSON.stringify(requestBody),
        connectTimeout: 30000,
        readTimeout: 300000
      });

      httpRequest.destroy();
      const code = response.responseCode;
      const body = response.result ? response.result.toString() : '';

      if (code !== 200 || body.length === 0) {
        onError(`HTTP ${code}: ${body.substring(0, 300)}`);
        return;
      }

      const respObj: Record<string, Object> = JSON.parse(body);

      // Check MiniMax base_resp for API-level errors
      const baseResp = respObj['base_resp'] as Record<string, Object>;
      if (baseResp) {
        const statusCode = baseResp['status_code'] as number;
        if (statusCode !== 0) {
          const statusMsg = baseResp['status_msg'] as string;
          onError(`API error (${statusCode}): ${statusMsg}`);
          return;
        }
      }

      // Extract content from choices
      const choices = respObj['choices'] as Object[];
      if (choices && choices.length > 0) {
        const choice = choices[0] as Record<string, Object>;
        const message = choice['message'] as Record<string, Object>;
        if (message && message['content']) {
          const content = message['content'].toString();
          onChunk(content);
          history.push({ role: 'assistant', content: content });
          onComplete();
          return;
        }
      }

      onError('No content in API response');
    } catch (err) {
      onError('Network error: ' + JSON.stringify(err));
      httpRequest.destroy();
    }
  }

  async testApiConnection(): Promise<string> {
    if (!this.hasApiKey()) {
      return 'No API key configured.';
    }

    const keyInfo = `Key: ${this.apiKey.substring(0, 6)}...${this.apiKey.substring(this.apiKey.length - 4)} (len=${this.apiKey.length})`;

    const sysMsg: MiniMaxMessage = { role: 'system', content: 'Reply with exactly: OK' };
    const userMsg: MiniMaxMessage = { role: 'user', content: 'Test' };
    const testRequest: MiniMaxRequest = {
      model: MODEL_NAME,
      messages: [sysMsg, userMsg],
      stream: false,
      max_tokens: 10
    };
    const requestBody = JSON.stringify(testRequest);

    for (let i = 0; i < API_URLS.length; i++) {
      const url = API_URLS[i];
      try {
        const httpRequest = http.createHttp();
        const response = await httpRequest.request(url, {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          },
          extraData: requestBody,
          connectTimeout: 15000,
          readTimeout: 30000
        });

        httpRequest.destroy();
        const code = response.responseCode;
        const body = response.result ? response.result.toString() : '';

        if (code === 200 && body.length > 0) {
          // Check MiniMax base_resp for API-level errors
          try {
            const respObj: Record<string, Object> = JSON.parse(body);
            const baseResp = respObj['base_resp'] as Record<string, Object>;
            if (baseResp) {
              const statusCode = baseResp['status_code'] as number;
              const statusMsg = baseResp['status_msg'] as string;
              if (statusCode !== 0) {
                if (i < API_URLS.length - 1) continue;
                return `API Error (${statusCode}): ${statusMsg}\n${keyInfo}\nEndpoint: ${url}`;
              }
            }
          } catch (e) {
            // Not JSON or no base_resp — might be SSE or valid response
          }

          if (i !== 0) {
            const tmp = API_URLS[0];
            API_URLS[0] = url;
            API_URLS[i] = tmp;
          }
          return `Success!\n${keyInfo}\nEndpoint: ${url}\nResponse: ${body.substring(0, 200)}`;
        } else if (i === API_URLS.length - 1) {
          return `HTTP ${code}\n${keyInfo}\nEndpoint: ${url}\nResponse: ${body.substring(0, 300)}`;
        }
      } catch (err) {
        if (i === API_URLS.length - 1) {
          return `Network error: ${JSON.stringify(err)}\n${keyInfo}\nEndpoint: ${url}`;
        }
      }
    }
    return 'All endpoints failed.';
  }

  clearSession(sessionId: string): void {
    this.chatHistory.delete(sessionId);
  }

  getTutorSystemPrompt(): string {
    return TUTOR_SYSTEM_PROMPT;
  }

  getPhotoSolveSystemPrompt(): string {
    return PHOTO_SOLVE_SYSTEM_PROMPT;
  }
}
