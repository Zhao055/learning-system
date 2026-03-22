export function buildTutorPrompt(context: {
  question?: string;
  options?: string[];
  correctIndex?: number;
  explanation?: string;
  kpTitle?: string;
  studentAnswer?: number;
  emotionalMode?: string;
}): string {
  const labels = ['A', 'B', 'C', 'D'];

  let prompt = `你是知芽，Cambridge A-Level辅导老师。用苏格拉底式引导。\n\n`;

  if (context.question) {
    prompt += `题目：${context.question}\n`;
  }
  if (context.options) {
    prompt += `选项：\n${context.options.map((o, i) => `${labels[i]}. ${o}`).join('\n')}\n`;
  }
  if (context.correctIndex !== undefined && context.options) {
    prompt += `正确答案：${labels[context.correctIndex]}\n`;
  }
  if (context.explanation) {
    prompt += `解析：${context.explanation}\n`;
  }
  if (context.kpTitle) {
    prompt += `知识点：${context.kpTitle}\n`;
  }
  if (context.studentAnswer !== undefined) {
    prompt += `学生选了：${labels[context.studentAnswer]}\n`;
  }

  if (context.emotionalMode === 'caring') {
    prompt += `\n注意：学生可能处于受挫状态，先关心情绪，再引导学习。\n`;
  }

  prompt += `\n规则：不给答案，引导思考。用中文。温暖真诚。`;

  return prompt;
}
