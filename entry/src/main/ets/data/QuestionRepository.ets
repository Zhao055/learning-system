import { Chapter, QuestionBank, KnowledgePoint, Question } from '../model/ChapterModel';
import { util } from '@kit.ArkTS';

export class QuestionRepository {
  private static instance: QuestionRepository;
  private papers: Map<string, QuestionBank> = new Map();

  private constructor() {}

  static getInstance(): QuestionRepository {
    if (!QuestionRepository.instance) {
      QuestionRepository.instance = new QuestionRepository();
    }
    return QuestionRepository.instance;
  }

  async loadPaper(context: Context, jsonFile: string, paperId: string): Promise<void> {
    if (this.papers.has(paperId)) return;
    try {
      const rawFile = context.resourceManager.getRawFileContentSync(jsonFile);
      const textDecoder = new util.TextDecoder('utf-8');
      const jsonStr = textDecoder.decodeToString(rawFile);
      const parsed: QuestionBank = JSON.parse(jsonStr);
      this.papers.set(paperId, parsed);
    } catch (e) {
      console.error(`Failed to load paper ${paperId}: ` + JSON.stringify(e));
    }
  }

  isPaperLoaded(paperId: string): boolean {
    return this.papers.has(paperId);
  }

  getChapters(paperId: string): Chapter[] {
    return this.papers.get(paperId)?.chapters ?? [];
  }

  getChapter(paperId: string, chapterId: string): Chapter | undefined {
    return this.papers.get(paperId)?.chapters.find(c => c.id === chapterId);
  }

  getKnowledgePoint(paperId: string, chapterId: string, kpId: string): KnowledgePoint | undefined {
    const chapter = this.getChapter(paperId, chapterId);
    return chapter?.knowledgePoints.find(kp => kp.id === kpId);
  }

  getQuestions(paperId: string, chapterId: string, kpId: string): Question[] {
    const kp = this.getKnowledgePoint(paperId, chapterId, kpId);
    return kp?.questions ?? [];
  }
}
