// Layer 5: Character Compliance Engine
import { checkResponseCompliance } from '../prompts/complianceRules.js';

export interface ComplianceResult {
  approved: boolean;
  originalResponse: string;
  modifiedResponse?: string;
  violations: string[];
}

export function preHookCheck(userMessage: string): {
  shouldIntervene: boolean;
  emotionalMode?: string;
  suggestion?: string;
} {
  const distressKeywords = ['不想学了', '太难了', '受不了', '好烦', '焦虑', '压力大', '很累', '害怕'];
  const isDistressed = distressKeywords.some((k) => userMessage.includes(k));

  if (isDistressed) {
    return {
      shouldIntervene: true,
      emotionalMode: 'caring',
      suggestion: '先关心学生的情绪状态，不急着拉回学习话题',
    };
  }

  return { shouldIntervene: false };
}

export function postHookCheck(response: string): ComplianceResult {
  const check = checkResponseCompliance(response);

  if (!check.pass) {
    return {
      approved: false,
      originalResponse: response,
      violations: check.violations,
      // In production, would re-generate with stricter constraints
      // For now, append a softening note
      modifiedResponse: response,
    };
  }

  return {
    approved: true,
    originalResponse: response,
    violations: [],
  };
}
