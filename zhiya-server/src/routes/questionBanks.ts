import { Hono } from 'hono';
import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const dataDir = join(__dirname, '../../data/question-banks');

const questionBanks = new Hono();

// Subject catalog
const SUBJECTS = [
  {
    id: 'math', name: 'Mathematics', nameCn: '数学', code: '9709', icon: '📐',
    color: '#4E6EF2', gradientColors: ['#4E6EF2', '#7B68EE'],
    papers: [
      { id: 'math_p1', name: 'P1 Pure Mathematics 1', nameCn: '纯数学 1', jsonFile: 'math_p1.json', chapterCount: 8, kpCount: 37, questionCount: 296, available: true },
      { id: 'math_p2', name: 'P2 Pure Mathematics 2', nameCn: '纯数学 2', jsonFile: 'math_p2.json', chapterCount: 6, kpCount: 6, questionCount: 30, available: true },
      { id: 'math_p3', name: 'P3 Pure Mathematics 3', nameCn: '纯数学 3', jsonFile: 'math_p3.json', chapterCount: 9, kpCount: 9, questionCount: 45, available: true },
      { id: 'math_m1', name: 'M1 Mechanics', nameCn: '力学', jsonFile: 'math_m1.json', chapterCount: 5, kpCount: 5, questionCount: 25, available: true },
      { id: 'math_s1', name: 'S1 Statistics 1', nameCn: '统计学 1', jsonFile: 'math_s1.json', chapterCount: 5, kpCount: 5, questionCount: 25, available: true },
      { id: 'math_s2', name: 'S2 Statistics 2', nameCn: '统计学 2', jsonFile: 'math_s2.json', chapterCount: 5, kpCount: 5, questionCount: 25, available: true },
    ],
  },
  {
    id: 'bio', name: 'Biology', nameCn: '生物', code: '9700', icon: '🧬',
    color: '#4CAF50', gradientColors: ['#4CAF50', '#66BB6A'],
    papers: [
      { id: 'bio_as', name: 'AS (Papers 1 & 2)', nameCn: 'AS 级别', jsonFile: 'bio_as.json', chapterCount: 11, kpCount: 11, questionCount: 55, available: true },
      { id: 'bio_a2', name: 'A2 (Papers 4 & 5)', nameCn: 'A2 级别', jsonFile: 'bio_a2.json', chapterCount: 8, kpCount: 8, questionCount: 40, available: true },
    ],
  },
  {
    id: 'psych', name: 'Psychology', nameCn: '心理学', code: '9990', icon: '🧠',
    color: '#9C27B0', gradientColors: ['#9C27B0', '#BA68C8'],
    papers: [
      { id: 'psych_p1', name: 'P1 AS Approaches', nameCn: 'AS 心理学方法', jsonFile: 'psych_p1.json', chapterCount: 4, kpCount: 4, questionCount: 20, available: true },
      { id: 'psych_p2', name: 'P2 AS Research Methods', nameCn: 'AS 研究方法', jsonFile: 'psych_p2.json', chapterCount: 3, kpCount: 3, questionCount: 15, available: true },
      { id: 'psych_p3', name: 'P3 A2 Specialist Options', nameCn: 'A2 专业选项', jsonFile: 'psych_p3.json', chapterCount: 4, kpCount: 4, questionCount: 20, available: true },
      { id: 'psych_p4', name: 'P4 A2 Research Methods', nameCn: 'A2 研究方法', jsonFile: 'psych_p4.json', chapterCount: 3, kpCount: 3, questionCount: 15, available: true },
    ],
  },
];

questionBanks.get('/subjects', (c) => {
  return c.json(SUBJECTS);
});

questionBanks.get('/papers/:id/bank', (c) => {
  const paperId = c.req.param('id');
  const paper = SUBJECTS.flatMap((s) => s.papers).find((p) => p.id === paperId);

  if (!paper) {
    return c.json({ error: 'Paper not found' }, 404);
  }

  const filePath = join(dataDir, paper.jsonFile);
  if (!existsSync(filePath)) {
    return c.json({ error: 'Question bank file not found' }, 404);
  }

  const data = JSON.parse(readFileSync(filePath, 'utf-8'));
  return c.json(data);
});

export default questionBanks;
