import { QuestionRepository } from '../data/QuestionRepository';
import { ProgressService } from '../service/ProgressService';
import { HomePage } from './HomePage';

@Entry
@Component
struct Index {
  @Provide navPathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    QuestionRepository.getInstance().loadPaper(getContext(this), 'math_p1.json', 'math_p1');
    ProgressService.getInstance().loadProgress(getContext(this));
  }

  build() {
    Navigation(this.navPathStack) {
      HomePage()
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}
