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
  chapterId: string;
  chapterTitle: string;
  knowledgePointId: string;
  knowledgePointTitle: string;
  totalQuestions: number;
  correctCount: number;
  answers: QuizAnswer[];
  timestamp: number;
}
