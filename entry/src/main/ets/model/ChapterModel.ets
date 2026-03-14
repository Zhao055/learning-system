export interface SubjectInfo {
  id: string;
  name: string;
  nameCn: string;
  code: string;
  icon: string;
  color: string;
  gradientColors: [string, string];
  papers: PaperInfo[];
}

export interface PaperInfo {
  id: string;
  name: string;
  nameCn: string;
  subjectId: string;
  jsonFile: string;
  chapterCount: number;
  kpCount: number;
  questionCount: number;
  available: boolean;
}

export interface Question {
  id: string;
  stem: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  difficulty: number;
}

export interface KnowledgePoint {
  id: string;
  title: string;
  titleCn: string;
  image: string;
  questions: Question[];
}

export interface Chapter {
  id: string;
  title: string;
  titleCn: string;
  knowledgePoints: KnowledgePoint[];
}

export interface QuestionBank {
  chapters: Chapter[];
}

export interface QuizAnswer {
  questionId: string;
  selectedIndex: number;
  isCorrect: boolean;
}

export interface QuizResult {
  paperId: string;
  paperName: string;
  chapterId: string;
  chapterTitle: string;
  knowledgePointId: string;
  knowledgePointTitle: string;
  totalQuestions: number;
  correctCount: number;
  answers: QuizAnswer[];
  timestamp: number;
}
