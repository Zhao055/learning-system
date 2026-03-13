import { QuestionRepository } from '../data/QuestionRepository';

@Entry
@Component
struct Index {
  @Provide navPathStack: NavPathStack = new NavPathStack();
  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    this.repo.loadQuestionBank(getContext(this));
  }

  @Builder
  routerMap(name: string, param: Object) {
    if (name === 'HomePage') {
      HomePage()
    } else if (name === 'ChapterListPage') {
      ChapterListPage()
    } else if (name === 'KnowledgeCardPage') {
      KnowledgeCardPage()
    } else if (name === 'QuizPage') {
      QuizPage()
    } else if (name === 'QuizResultPage') {
      QuizResultPage()
    } else if (name === 'CameraPage') {
      CameraPage()
    } else if (name === 'PhotoPreviewPage') {
      PhotoPreviewPage()
    } else if (name === 'SolutionPage') {
      SolutionPage()
    } else if (name === 'SettingsPage') {
      SettingsPage()
    }
  }

  build() {
    Navigation(this.navPathStack) {
      HomePage()
    }
    .navDestination(this.routerMap)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}
