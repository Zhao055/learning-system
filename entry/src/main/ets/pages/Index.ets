import { QuestionRepository } from '../data/QuestionRepository';
import { HomePage } from './HomePage';

@Entry
@Component
struct Index {
  @Provide navPathStack: NavPathStack = new NavPathStack();
  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    this.repo.loadQuestionBank(getContext(this));
  }

  build() {
    Navigation(this.navPathStack) {
      HomePage()
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}
