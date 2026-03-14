import { SubjectInfo, PaperInfo } from '../model/ChapterModel';

export const SUBJECTS: SubjectInfo[] = [
  {
    id: 'math',
    name: 'Mathematics',
    nameCn: '数学',
    code: '9709',
    icon: '📐',
    color: '#4E6EF2',
    gradientColors: ['#4E6EF2', '#7B68EE'],
    papers: [
      {
        id: 'math_p1',
        name: 'P1 Pure Mathematics 1',
        nameCn: '纯数学 1',
        subjectId: 'math',
        jsonFile: 'math_p1.json',
        chapterCount: 8,
        kpCount: 37,
        questionCount: 185,
        available: true
      },
      {
        id: 'math_p2',
        name: 'P2 Pure Mathematics 2',
        nameCn: '纯数学 2',
        subjectId: 'math',
        jsonFile: 'math_p2.json',
        chapterCount: 6,
        kpCount: 6,
        questionCount: 18,
        available: true
      },
      {
        id: 'math_p3',
        name: 'P3 Pure Mathematics 3',
        nameCn: '纯数学 3',
        subjectId: 'math',
        jsonFile: 'math_p3.json',
        chapterCount: 9,
        kpCount: 9,
        questionCount: 27,
        available: true
      },
      {
        id: 'math_m1',
        name: 'M1 Mechanics',
        nameCn: '力学',
        subjectId: 'math',
        jsonFile: 'math_m1.json',
        chapterCount: 5,
        kpCount: 5,
        questionCount: 15,
        available: true
      },
      {
        id: 'math_s1',
        name: 'S1 Statistics 1',
        nameCn: '统计学 1',
        subjectId: 'math',
        jsonFile: 'math_s1.json',
        chapterCount: 5,
        kpCount: 5,
        questionCount: 15,
        available: true
      },
      {
        id: 'math_s2',
        name: 'S2 Statistics 2',
        nameCn: '统计学 2',
        subjectId: 'math',
        jsonFile: 'math_s2.json',
        chapterCount: 5,
        kpCount: 5,
        questionCount: 15,
        available: true
      }
    ]
  },
  {
    id: 'bio',
    name: 'Biology',
    nameCn: '生物',
    code: '9700',
    icon: '🧬',
    color: '#4CAF50',
    gradientColors: ['#4CAF50', '#66BB6A'],
    papers: [
      {
        id: 'bio_as',
        name: 'AS (Papers 1 & 2)',
        nameCn: 'AS 级别',
        subjectId: 'bio',
        jsonFile: 'bio_as.json',
        chapterCount: 11,
        kpCount: 11,
        questionCount: 33,
        available: true
      },
      {
        id: 'bio_a2',
        name: 'A2 (Papers 4 & 5)',
        nameCn: 'A2 级别',
        subjectId: 'bio',
        jsonFile: 'bio_a2.json',
        chapterCount: 8,
        kpCount: 8,
        questionCount: 24,
        available: true
      }
    ]
  },
  {
    id: 'psych',
    name: 'Psychology',
    nameCn: '心理学',
    code: '9990',
    icon: '🧠',
    color: '#9C27B0',
    gradientColors: ['#9C27B0', '#BA68C8'],
    papers: [
      {
        id: 'psych_p1',
        name: 'P1 AS Approaches',
        nameCn: 'AS 心理学方法',
        subjectId: 'psych',
        jsonFile: 'psych_p1.json',
        chapterCount: 4,
        kpCount: 4,
        questionCount: 12,
        available: true
      },
      {
        id: 'psych_p2',
        name: 'P2 AS Research Methods',
        nameCn: 'AS 研究方法',
        subjectId: 'psych',
        jsonFile: 'psych_p2.json',
        chapterCount: 3,
        kpCount: 3,
        questionCount: 9,
        available: true
      },
      {
        id: 'psych_p3',
        name: 'P3 A2 Specialist Options',
        nameCn: 'A2 专业选项',
        subjectId: 'psych',
        jsonFile: 'psych_p3.json',
        chapterCount: 4,
        kpCount: 4,
        questionCount: 12,
        available: true
      },
      {
        id: 'psych_p4',
        name: 'P4 A2 Research Methods',
        nameCn: 'A2 研究方法',
        subjectId: 'psych',
        jsonFile: 'psych_p4.json',
        chapterCount: 3,
        kpCount: 3,
        questionCount: 9,
        available: true
      }
    ]
  }
];

export function getSubject(subjectId: string): SubjectInfo | undefined {
  return SUBJECTS.find(s => s.id === subjectId);
}

export function getPaper(paperId: string): PaperInfo | undefined {
  for (const subject of SUBJECTS) {
    const paper = subject.papers.find(p => p.id === paperId);
    if (paper) return paper;
  }
  return undefined;
}

export function getSubjectForPaper(paperId: string): SubjectInfo | undefined {
  for (const subject of SUBJECTS) {
    if (subject.papers.some(p => p.id === paperId)) return subject;
  }
  return undefined;
}
