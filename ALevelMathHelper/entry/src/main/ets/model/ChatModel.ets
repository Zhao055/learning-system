export interface ChatMessage {
  id: string;
  role: string;
  content: string;
  timestamp: number;
  isStreaming?: boolean;
}

export interface MiniMaxRequest {
  model: string;
  messages: MiniMaxMessage[];
  stream: boolean;
  temperature?: number;
  max_tokens?: number;
}

export interface MiniMaxMessage {
  role: string;
  content: string;
}

export interface MiniMaxChoice {
  delta?: MiniMaxDelta;
  message?: MiniMaxDelta;
  finish_reason?: string;
}

export interface MiniMaxDelta {
  role?: string;
  content?: string;
}

export interface MiniMaxResponse {
  id: string;
  choices: MiniMaxChoice[];
}
