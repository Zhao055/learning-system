// Emotion detection and emotional profile accumulation

export interface EmotionAnalysis {
  detectedMood: string;
  confidence: number;
  suggestedResponse: string;
  shouldSwitchToWarmMode: boolean;
}

export function analyzeEmotion(text: string, context?: string): EmotionAnalysis {
  const frustrated = ['太难了', '不会', '做不到', '错了', '又错', '烦', '不想'];
  const anxious = ['考试', '紧张', '害怕', '焦虑', '来不及', '压力'];
  const lowEnergy = ['累', '困', '没劲', '不想学', '无聊'];
  const happy = ['会了', '对了', '懂了', '太好了', '开心', '有趣'];

  const lower = text.toLowerCase();

  if (frustrated.some((k) => lower.includes(k))) {
    return {
      detectedMood: 'frustrated',
      confidence: 0.8,
      suggestedResponse: '先停下来，深呼吸。做不出来没关系的。',
      shouldSwitchToWarmMode: true,
    };
  }

  if (anxious.some((k) => lower.includes(k))) {
    return {
      detectedMood: 'anxious',
      confidence: 0.7,
      suggestedResponse: '一件一件来，不用一下子全做完。',
      shouldSwitchToWarmMode: true,
    };
  }

  if (lowEnergy.some((k) => lower.includes(k))) {
    return {
      detectedMood: 'lowEnergy',
      confidence: 0.7,
      suggestedResponse: '今天不学也没关系。休息好了再来。',
      shouldSwitchToWarmMode: true,
    };
  }

  if (happy.some((k) => lower.includes(k))) {
    return {
      detectedMood: 'smooth',
      confidence: 0.8,
      suggestedResponse: '',
      shouldSwitchToWarmMode: false,
    };
  }

  return {
    detectedMood: 'neutral',
    confidence: 0.5,
    suggestedResponse: '',
    shouldSwitchToWarmMode: false,
  };
}
