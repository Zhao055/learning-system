import { preferences } from '@kit.ArkData';
import { ProgressRecord, KpProgress, ChapterProgress, PaperProgress } from '../model/ChapterModel';
import { QuestionRepository } from '../data/QuestionRepository';

const PREF_NAME = 'progress_data';
const RECORDS_KEY = 'progress_records';

export class ProgressService {
  private static instance: ProgressService;
  private records: ProgressRecord[] = [];
  private loaded: boolean = false;

  private constructor() {}

  static getInstance(): ProgressService {
    if (!ProgressService.instance) {
      ProgressService.instance = new ProgressService();
    }
    return ProgressService.instance;
  }

  async loadProgress(context: Context): Promise<void> {
    if (this.loaded) return;
    try {
      const store = preferences.getPreferencesSync(context, { name: PREF_NAME });
      const raw: string = store.getSync(RECORDS_KEY, '[]').toString();
      this.records = JSON.parse(raw) as ProgressRecord[];
      this.loaded = true;
    } catch (e) {
      console.error('Failed to load progress: ' + JSON.stringify(e));
      this.records = [];
      this.loaded = true;
    }
  }

  private async saveRecords(context: Context): Promise<void> {
    try {
      const store = preferences.getPreferencesSync(context, { name: PREF_NAME });
      store.putSync(RECORDS_KEY, JSON.stringify(this.records));
      await store.flush();
    } catch (e) {
      console.error('Failed to save progress: ' + JSON.stringify(e));
    }
  }

  async recordAnswer(context: Context, paperId: string, chapterId: string, kpId: string,
    questionId: string, correct: boolean, selectedIndex: number): Promise<void> {
    // Remove existing record for this question (keep only latest attempt)
    this.records = this.records.filter(r =>
      !(r.paperId === paperId && r.chapterId === chapterId && r.kpId === kpId && r.questionId === questionId)
    );
    const record: ProgressRecord = {
      paperId: paperId,
      chapterId: chapterId,
      kpId: kpId,
      questionId: questionId,
      correct: correct,
      selectedIndex: selectedIndex,
      timestamp: Date.now()
    };
    this.records.push(record);
    await this.saveRecords(context);
  }

  getKpProgress(paperId: string, chapterId: string, kpId: string): KpProgress {
    const repo = QuestionRepository.getInstance();
    const questions = repo.getQuestions(paperId, chapterId, kpId);
    const total = questions.length;
    const kpRecords = this.records.filter(r =>
      r.paperId === paperId && r.chapterId === chapterId && r.kpId === kpId
    );
    const attempted = kpRecords.length;
    const correct = kpRecords.filter(r => r.correct).length;
    return { total: total, correct: correct, attempted: attempted };
  }

  getChapterProgress(paperId: string, chapterId: string): ChapterProgress {
    const repo = QuestionRepository.getInstance();
    const chapter = repo.getChapter(paperId, chapterId);
    const kps = chapter?.knowledgePoints ?? [];
    const totalKps = kps.length;
    let completedKps = 0;
    let totalAttempted = 0;
    let totalCorrect = 0;

    for (const kp of kps) {
      const kpProg = this.getKpProgress(paperId, chapterId, kp.id);
      if (kpProg.attempted > 0) {
        completedKps++;
        totalAttempted += kpProg.attempted;
        totalCorrect += kpProg.correct;
      }
    }
    const correctRate = totalAttempted > 0 ? Math.round((totalCorrect / totalAttempted) * 100) : 0;
    return { totalKps: totalKps, completedKps: completedKps, correctRate: correctRate };
  }

  getPaperProgress(paperId: string): PaperProgress {
    const repo = QuestionRepository.getInstance();
    const chapters = repo.getChapters(paperId);
    const totalChapters = chapters.length;
    let completedChapters = 0;
    let totalAttempted = 0;
    let totalCorrect = 0;

    for (const ch of chapters) {
      const chProg = this.getChapterProgress(paperId, ch.id);
      if (chProg.completedKps > 0) {
        completedChapters++;
      }
      const chRecords = this.records.filter(r => r.paperId === paperId && r.chapterId === ch.id);
      totalAttempted += chRecords.length;
      totalCorrect += chRecords.filter(r => r.correct).length;
    }
    const correctRate = totalAttempted > 0 ? Math.round((totalCorrect / totalAttempted) * 100) : 0;
    return { totalChapters: totalChapters, completedChapters: completedChapters, correctRate: correctRate };
  }

  getTotalStats(): { totalAnswered: number; totalCorrect: number; accuracy: number } {
    const totalAnswered = this.records.length;
    const totalCorrect = this.records.filter(r => r.correct).length;
    const accuracy = totalAnswered > 0 ? Math.round((totalCorrect / totalAnswered) * 100) : 0;
    return { totalAnswered: totalAnswered, totalCorrect: totalCorrect, accuracy: accuracy };
  }

  getWrongAnswers(paperId: string): ProgressRecord[] {
    if (paperId.length > 0) {
      return this.records.filter(r => !r.correct && r.paperId === paperId);
    }
    return this.records.filter(r => !r.correct);
  }

  getAllWrongAnswers(): ProgressRecord[] {
    return this.records.filter(r => !r.correct);
  }

  getWrongAnswerCount(): number {
    return this.records.filter(r => !r.correct).length;
  }

  async removeWrongAnswer(context: Context, paperId: string, chapterId: string, kpId: string,
    questionId: string): Promise<void> {
    this.records = this.records.filter(r =>
      !(r.paperId === paperId && r.chapterId === chapterId && r.kpId === kpId &&
        r.questionId === questionId && !r.correct)
    );
    await this.saveRecords(context);
  }

  async clearProgress(context: Context, paperId: string): Promise<void> {
    if (paperId.length > 0) {
      this.records = this.records.filter(r => r.paperId !== paperId);
    } else {
      this.records = [];
    }
    await this.saveRecords(context);
  }

  async clearWrongAnswers(context: Context, paperId: string): Promise<void> {
    if (paperId.length > 0) {
      this.records = this.records.filter(r => !(r.paperId === paperId && !r.correct));
    } else {
      this.records = this.records.filter(r => r.correct);
    }
    await this.saveRecords(context);
  }
}
