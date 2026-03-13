import { Chapter, QuestionBank, KnowledgePoint, Question } from '../model/ChapterModel';
import { util } from '@kit.ArkTS';

export class QuestionRepository {
  private static instance: QuestionRepository;
  private questionBank: QuestionBank | null = null;

  private constructor() {}

  static getInstance(): QuestionRepository {
    if (!QuestionRepository.instance) {
      QuestionRepository.instance = new QuestionRepository();
    }
    return QuestionRepository.instance;
  }

  async loadQuestionBank(context: Context): Promise<void> {
    if (this.questionBank) return;
    try {
      const rawFile = context.resourceManager.getRawFileContentSync('question_bank.json');
      const textDecoder = new util.TextDecoder('utf-8');
      const jsonStr = textDecoder.decodeToString(rawFile);
      this.questionBank = JSON.parse(jsonStr) as QuestionBank;
    } catch (e) {
      console.error('Failed to load question bank: ' + JSON.stringify(e));
    }
  }

  getChapters(): Chapter[] {
    return this.questionBank?.chapters ?? [];
  }

  getChapter(chapterId: string): Chapter | undefined {
    return this.questionBank?.chapters.find(c => c.id === chapterId);
  }

  getKnowledgePoint(chapterId: string, kpId: string): KnowledgePoint | undefined {
    const chapter = this.getChapter(chapterId);
    return chapter?.knowledgePoints.find(kp => kp.id === kpId);
  }

  getQuestions(chapterId: string, kpId: string): Question[] {
    const kp = this.getKnowledgePoint(chapterId, kpId);
    return kp?.questions ?? [];
  }
}
