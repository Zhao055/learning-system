import { QuestionRepository } from '../data/QuestionRepository';
import { Question, KnowledgePoint, QuizAnswer, QuizResult } from '../model/ChapterModel';
import { getPaper } from '../data/SubjectData';
import { MiniMaxService } from '../service/MiniMaxService';
import { ProgressService } from '../service/ProgressService';
import { ChatMessage } from '../model/ChatModel';
import { OptionCard } from '../components/OptionCard';
import { ResultBadge } from '../components/ResultBadge';

@Builder
export function QuizPageBuilder() {
  QuizPage()
}

@Component
export struct QuizPage {
  @Consume navPathStack: NavPathStack;
  @State paperId: string = '';
  @State chapterId: string = '';
  @State kpId: string = '';
  @State knowledgePoint: KnowledgePoint | undefined = undefined;
  @State questions: Question[] = [];
  @State currentIndex: number = 0;
  @State selectedOption: number = -1;
  @State showResult: boolean = false;
  @State answers: QuizAnswer[] = [];
  @State showChatPanel: boolean = false;
  @State chatMessages: ChatMessage[] = [];
  @State chatInput: string = '';
  @State isStreaming: boolean = false;
  private currentChatSessionId: string = '';

  aboutToDisappear(): void {
    if (this.currentChatSessionId) {
      MiniMaxService.getInstance().clearSession(this.currentChatSessionId);
    }
  }

  aboutToAppear(): void {
    const params = this.navPathStack.getParamByName('QuizPage') as Object[];
    if (params && params.length > 0) {
      const p = params[0] as string[];
      this.paperId = p[0];
      this.chapterId = p[1];
      this.kpId = p[2];
      const repo = QuestionRepository.getInstance();
      this.knowledgePoint = repo.getKnowledgePoint(this.paperId, this.chapterId, this.kpId);
      this.questions = repo.getQuestions(this.paperId, this.chapterId, this.kpId);
    }
  }

  private getCurrentQuestion(): Question | undefined {
    return this.questions[this.currentIndex];
  }

  private getIsCorrect(): boolean {
    const q = this.getCurrentQuestion();
    return q !== undefined && this.selectedOption === q.correctIndex;
  }

  private submitAnswer(): void {
    const q = this.getCurrentQuestion();
    if (this.selectedOption < 0 || !q) return;
    this.showResult = true;

    const isCorrect = this.getIsCorrect();
    const answer: QuizAnswer = {
      questionId: q.id,
      selectedIndex: this.selectedOption,
      isCorrect: isCorrect
    };
    this.answers.push(answer);

    // Record answer for progress tracking
    ProgressService.getInstance().recordAnswer(
      getContext(this), this.paperId, this.chapterId, this.kpId,
      q.id, isCorrect, this.selectedOption
    );
  }

  private nextQuestion(): void {
    if (this.currentIndex < this.questions.length - 1) {
      this.currentIndex++;
      this.selectedOption = -1;
      this.showResult = false;
    } else {
      const chapter = QuestionRepository.getInstance().getChapter(this.paperId, this.chapterId);
      const paper = getPaper(this.paperId);
      const result: QuizResult = {
        paperId: this.paperId,
        paperName: paper?.name ?? '',
        chapterId: this.chapterId,
        chapterTitle: chapter?.title ?? '',
        knowledgePointId: this.kpId,
        knowledgePointTitle: this.knowledgePoint?.title ?? '',
        totalQuestions: this.questions.length,
        correctCount: this.answers.filter(a => a.isCorrect).length,
        answers: this.answers,
        timestamp: Date.now()
      };
      this.navPathStack.pushPathByName('QuizResultPage', result);
    }
  }

  private closeChatPanel(): void {
    this.showChatPanel = false;
    if (this.currentChatSessionId) {
      MiniMaxService.getInstance().clearSession(this.currentChatSessionId);
      this.currentChatSessionId = '';
    }
  }

  private openAIChat(): void {
    const q = this.getCurrentQuestion();
    if (!q) return;

    if (!MiniMaxService.getInstance().hasApiKey()) {
      AlertDialog.show({
        title: 'API Key Required',
        message: 'Please configure your MiniMax API Key in Settings first.',
        primaryButton: {
          value: 'Go to Settings',
          action: () => {
            this.navPathStack.pushPathByName('SettingsPage', null);
          }
        },
        secondaryButton: {
          value: 'Cancel',
          action: () => {}
        }
      });
      return;
    }

    const sessionId = `quiz_${q.id}`;
    this.currentChatSessionId = sessionId;
    const service = MiniMaxService.getInstance();
    const userAnswer = q.options[this.selectedOption];
    const correctAnswer = q.options[q.correctIndex];
    const paper = getPaper(this.paperId);

    service.initTutorSession(sessionId, this.knowledgePoint?.title ?? '',
      q.stem, userAnswer, correctAnswer, q.explanation, this.getIsCorrect(),
      paper?.name ?? '');

    this.chatMessages = [];
    this.isStreaming = true;
    this.showChatPanel = true;

    service.sendMessageStream(sessionId, '',
      (chunk: string) => {
        if (this.chatMessages.length === 0 || this.chatMessages[this.chatMessages.length - 1].role !== 'assistant') {
          const msg: ChatMessage = {
            id: `ai_${Date.now()}`,
            role: 'assistant',
            content: chunk,
            timestamp: Date.now(),
            isStreaming: true
          };
          this.chatMessages = [...this.chatMessages, msg];
        } else {
          const msgs = [...this.chatMessages];
          const last = msgs[msgs.length - 1];
          msgs[msgs.length - 1] = {
            id: last.id,
            role: last.role,
            content: last.content + chunk,
            timestamp: last.timestamp,
            isStreaming: true
          };
          this.chatMessages = msgs;
        }
      },
      () => {
        this.isStreaming = false;
        if (this.chatMessages.length > 0) {
          const msgs = [...this.chatMessages];
          const last = msgs[msgs.length - 1];
          msgs[msgs.length - 1] = {
            id: last.id, role: last.role, content: last.content,
            timestamp: last.timestamp, isStreaming: false
          };
          this.chatMessages = msgs;
        }
      },
      (err: string) => {
        this.isStreaming = false;
        const errMsg: ChatMessage = {
          id: `err_${Date.now()}`, role: 'assistant',
          content: `Error: ${err}`, timestamp: Date.now()
        };
        this.chatMessages = [...this.chatMessages, errMsg];
      }
    );
  }

  private sendChatMessage(): void {
    if (!this.chatInput.trim() || this.isStreaming) return;
    const userMsg: ChatMessage = {
      id: `user_${Date.now()}`, role: 'user',
      content: this.chatInput.trim(), timestamp: Date.now()
    };
    this.chatMessages = [...this.chatMessages, userMsg];
    const message = this.chatInput.trim();
    this.chatInput = '';
    this.isStreaming = true;

    const q = this.getCurrentQuestion();
    const sessionId = `quiz_${q?.id ?? 'unknown'}`;
    MiniMaxService.getInstance().sendMessageStream(sessionId, message,
      (chunk: string) => {
        const msgs = [...this.chatMessages];
        if (msgs.length === 0 || msgs[msgs.length - 1].role !== 'assistant' || !msgs[msgs.length - 1].isStreaming) {
          msgs.push({
            id: `ai_${Date.now()}`, role: 'assistant',
            content: chunk, timestamp: Date.now(), isStreaming: true
          });
        } else {
          const last = msgs[msgs.length - 1];
          msgs[msgs.length - 1] = {
            id: last.id, role: last.role, content: last.content + chunk,
            timestamp: last.timestamp, isStreaming: true
          };
        }
        this.chatMessages = msgs;
      },
      () => {
        this.isStreaming = false;
        const msgs = [...this.chatMessages];
        if (msgs.length > 0) {
          const last = msgs[msgs.length - 1];
          msgs[msgs.length - 1] = {
            id: last.id, role: last.role, content: last.content,
            timestamp: last.timestamp, isStreaming: false
          };
          this.chatMessages = msgs;
        }
      },
      (err: string) => {
        this.isStreaming = false;
        this.chatMessages = [...this.chatMessages, {
          id: `err_${Date.now()}`, role: 'assistant',
          content: `Error: ${err}`, timestamp: Date.now()
        }];
      }
    );
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // Header
          Row() {
            Button({ type: ButtonType.Circle }) {
              Image($r('sys.media.ohos_ic_public_arrow_left'))
                .width(24).height(24).fillColor('#333333')
            }
            .width(40).height(40).backgroundColor('#F0F0F0')
            .onClick(() => { this.navPathStack.pop(); })

            Column() {
              Text(this.knowledgePoint?.title ?? '')
                .fontSize(16).fontWeight(FontWeight.Bold).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(`Question ${this.currentIndex + 1} / ${this.questions.length}`)
                .fontSize(13).fontColor('#999999').margin({ top: 2 })
            }
            .margin({ left: 12 }).layoutWeight(1).alignItems(HorizontalAlign.Start)
          }
          .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 8 })

          // Progress bar
          Row() {
            ForEach(this.questions, (q: Question, idx: number) => {
              Column()
                .height(4)
                .layoutWeight(1)
                .margin({ left: idx > 0 ? 4 : 0 })
                .borderRadius(2)
                .backgroundColor(idx < this.currentIndex ? '#4CAF50' :
                                 idx === this.currentIndex ? '#4E6EF2' : '#E0E0E0')
            }, (q: Question) => q.id)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 4, bottom: 16 })

          // Question content
          Scroll() {
            Column({ space: 16 }) {
              // Question stem
              Text(this.getCurrentQuestion()?.stem ?? '')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .lineHeight(28)
                .width('100%')
                .padding(20)
                .backgroundColor('#FFFFFF')
                .borderRadius(16)
                .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 2 })

              // Options
              ForEach(this.getCurrentQuestion()?.options ?? [], (option: string, idx: number) => {
                OptionCard({
                  text: option,
                  index: idx,
                  isSelected: this.selectedOption === idx,
                  isCorrect: idx === this.getCurrentQuestion()?.correctIndex,
                  showResult: this.showResult,
                  onSelect: () => { this.selectedOption = idx; }
                })
              }, (option: string, idx: number) => `q${this.currentIndex}_opt_${idx}`)

              // Result feedback (inline)
              if (this.showResult) {
                // Compact result banner
                Row() {
                  Text(this.getIsCorrect() ? '✓' : '✗')
                    .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                    .width(36).height(36).textAlign(TextAlign.Center)
                    .borderRadius(18)
                    .backgroundColor(this.getIsCorrect() ? '#4CAF50' : '#F44336')
                  Text(this.getIsCorrect() ? 'Correct!' : 'Incorrect')
                    .fontSize(16).fontWeight(FontWeight.Bold)
                    .fontColor(this.getIsCorrect() ? '#4CAF50' : '#F44336')
                    .margin({ left: 12 })
                }
                .width('100%')
                .padding(12)
                .backgroundColor(this.getIsCorrect() ? '#E8F5E9' : '#FFEBEE')
                .borderRadius(12)

                // Explanation
                Column() {
                  Text('Explanation')
                    .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#4E6EF2')
                  Text(this.getCurrentQuestion()?.explanation ?? '')
                    .fontSize(14).fontColor('#333333').lineHeight(22).margin({ top: 8 })
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#F0F4FF')
                .borderRadius(12)
              }
            }
            .padding({ left: 20, right: 20, bottom: 20 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)

          // Fixed bottom action bar
          Column() {
            if (!this.showResult) {
              Button('Submit Answer')
                .width('100%').height(48)
                .backgroundColor(this.selectedOption >= 0 ? '#4E6EF2' : '#CCCCCC')
                .fontColor('#FFFFFF').fontSize(16).borderRadius(12)
                .enabled(this.selectedOption >= 0)
                .onClick(() => { this.submitAnswer(); })
            } else {
              Row({ space: 12 }) {
                Button('Ask AI')
                  .layoutWeight(1).height(44)
                  .backgroundColor('#FF8E53').fontColor('#FFFFFF')
                  .borderRadius(12).fontSize(15)
                  .onClick(() => { this.openAIChat(); })

                Button(this.currentIndex < this.questions.length - 1 ? 'Next' : 'Results')
                  .layoutWeight(1).height(44)
                  .backgroundColor('#4E6EF2').fontColor('#FFFFFF')
                  .borderRadius(12).fontSize(15)
                  .onClick(() => { this.nextQuestion(); })
              }
              .width('100%')
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 12, bottom: 16 })
          .backgroundColor('#FFFFFF')
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: -2 })
        }
        .width('100%').height('100%').backgroundColor('#F5F5F5')

        // Chat Panel (half-modal)
        if (this.showChatPanel) {
          Column() {
            Column()
              .width('100%')
              .layoutWeight(1)
              .backgroundColor('rgba(0,0,0,0.4)')
              .onClick(() => { this.closeChatPanel(); })

            Column() {
              Column()
                .width(40).height(4).borderRadius(2)
                .backgroundColor('#CCCCCC').margin({ top: 8, bottom: 8 })

              Row() {
                Text('Ask AI Tutor').fontSize(18).fontWeight(FontWeight.Bold)
                Blank()
                Button({ type: ButtonType.Circle }) {
                  Text('X').fontSize(16).fontColor('#666666')
                }
                .width(32).height(32).backgroundColor('#F0F0F0')
                .onClick(() => { this.closeChatPanel(); })
              }
              .width('100%').padding({ left: 20, right: 20 })

              List() {
                ForEach(this.chatMessages, (msg: ChatMessage) => {
                  ListItem() {
                    Column() {
                      if (msg.role === 'user') {
                        Row() {
                          Blank()
                          Text(msg.content)
                            .fontSize(14).fontColor('#FFFFFF').lineHeight(22)
                            .padding(12).backgroundColor('#4E6EF2')
                            .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 12, bottomRight: 4 })
                            .constraintSize({ maxWidth: '80%' })
                        }.width('100%')
                      } else {
                        Row() {
                          Text(msg.content + (msg.isStreaming ? '|' : ''))
                            .fontSize(14).fontColor('#333333').lineHeight(22)
                            .padding(12).backgroundColor('#F5F5F5')
                            .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 4, bottomRight: 12 })
                            .constraintSize({ maxWidth: '80%' })
                          Blank()
                        }.width('100%')
                      }
                    }.padding({ left: 16, right: 16, top: 4, bottom: 4 })
                  }
                }, (msg: ChatMessage) => msg.id)
              }
              .layoutWeight(1)
              .scrollBar(BarState.Off)

              Row() {
                TextInput({ placeholder: 'Ask a question...', text: this.chatInput })
                  .layoutWeight(1).height(40).borderRadius(20)
                  .backgroundColor('#F5F5F5').fontSize(14)
                  .onChange((value: string) => { this.chatInput = value; })
                  .onSubmit((enterKey: EnterKeyType) => { this.sendChatMessage(); })

                Button({ type: ButtonType.Circle }) {
                  Text('>').fontSize(18).fontColor('#FFFFFF')
                }
                .width(40).height(40)
                .backgroundColor(this.chatInput.trim().length > 0 ? '#4E6EF2' : '#CCCCCC')
                .margin({ left: 8 })
                .enabled(this.chatInput.trim().length > 0 && !this.isStreaming)
                .onClick(() => { this.sendChatMessage(); })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 8, bottom: 16 })
            }
            .width('100%')
            .height('65%')
            .backgroundColor('#FFFFFF')
            .borderRadius({ topLeft: 20, topRight: 20 })
          }
          .width('100%').height('100%')
        }
      }
    }
    .hideTitleBar(true)
  }
}
