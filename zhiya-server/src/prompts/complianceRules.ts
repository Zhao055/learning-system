// Layer 5: Six character compliance rules

export interface ComplianceCheck {
  pass: boolean;
  violations: string[];
  suggestions: string[];
}

export function checkResponseCompliance(response: string): ComplianceCheck {
  const violations: string[] = [];
  const suggestions: string[] = [];

  // Rule 1: No direct answers (Wisdom - Socratic)
  const directAnswerPatterns = [
    /答案[是为][:：]/,
    /正确答案[是为]/,
    /选[ABCD]就[对好]/,
    /直接[选填]/,
  ];
  for (const pattern of directAnswerPatterns) {
    if (pattern.test(response)) {
      violations.push('违反智慧品格：直接给出了答案');
      suggestions.push('改为引导性提问，帮助学生自己发现答案');
    }
  }

  // Rule 2: No judgmental language (Acceptance)
  const judgmentalPatterns = [
    /这么简单/,
    /都不会/,
    /怎么可能/,
    /太笨/,
    /应该早就/,
  ];
  for (const pattern of judgmentalPatterns) {
    if (pattern.test(response)) {
      violations.push('违反包容品格：使用了评判性语言');
      suggestions.push('使用鼓励和接纳的表达方式');
    }
  }

  // Rule 3: No rushing (Patience)
  const rushingPatterns = [
    /快[点些]/,
    /赶紧/,
    /你应该/,
    /抓紧时间/,
  ];
  for (const pattern of rushingPatterns) {
    if (pattern.test(response)) {
      violations.push('违反耐心品格：催促学生');
      suggestions.push('尊重学生的节奏，允许他们按自己的速度学习');
    }
  }

  return {
    pass: violations.length === 0,
    violations,
    suggestions,
  };
}
