import { QuestionRepository } from '../data/QuestionRepository';
import { HomePage } from './HomePage';

@Entry
@Component
struct Index {
  @Provide navPathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    QuestionRepository.getInstance().loadPaper(getContext(this), 'math_p1.json', 'math_p1');
  }

  build() {
    Navigation(this.navPathStack) {
      HomePage()
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}
