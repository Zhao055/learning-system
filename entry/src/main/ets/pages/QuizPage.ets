import { QuestionRepository } from '../data/QuestionRepository';
import { Question, KnowledgePoint, QuizAnswer, QuizResult } from '../model/ChapterModel';
import { MiniMaxService } from '../service/MiniMaxService';
import { ChatMessage } from '../model/ChatModel';
import { OptionCard } from '../components/OptionCard';
import { ResultBadge } from '../components/ResultBadge';

@Component
export struct QuizPage {
  @Consume navPathStack: NavPathStack;
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

  aboutToAppear(): void {
    const params = this.navPathStack.getParamByName('QuizPage') as string[][];
    if (params && params.length > 0) {
      const p = params[0];
      this.chapterId = p[0];
      this.kpId = p[1];
      const repo = QuestionRepository.getInstance();
      this.knowledgePoint = repo.getKnowledgePoint(this.chapterId, this.kpId);
      this.questions = repo.getQuestions(this.chapterId, this.kpId);
    }
  }

  private get currentQuestion(): Question | undefined {
    return this.questions[this.currentIndex];
  }

  private get isCorrect(): boolean {
    return this.selectedOption === this.currentQuestion?.correctIndex;
  }

  private submitAnswer(): void {
    if (this.selectedOption < 0 || !this.currentQuestion) return;
    this.showResult = true;

    const answer: QuizAnswer = {
      questionId: this.currentQuestion.id,
      selectedIndex: this.selectedOption,
      isCorrect: this.isCorrect
    };
    this.answers.push(answer);
  }

  private nextQuestion(): void {
    if (this.currentIndex < this.questions.length - 1) {
      this.currentIndex++;
      this.selectedOption = -1;
      this.showResult = false;
    } else {
      // All questions done - go to result page
      const chapter = QuestionRepository.getInstance().getChapter(this.chapterId);
      const result: QuizResult = {
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

  private openAIChat(): void {
    const q = this.currentQuestion;
    if (!q) return;
    const sessionId = `quiz_${q.id}`;
    const service = MiniMaxService.getInstance();
    const userAnswer = q.options[this.selectedOption];
    const correctAnswer = q.options[q.correctIndex];

    service.initTutorSession(sessionId, this.knowledgePoint?.title ?? '',
      q.stem, userAnswer, correctAnswer, q.explanation, this.isCorrect);

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

    const q = this.currentQuestion;
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
            ForEach(this.questions, (_: Question, idx: number) => {
              Column()
                .height(4)
                .layoutWeight(1)
                .margin({ left: idx > 0 ? 4 : 0 })
                .borderRadius(2)
                .backgroundColor(idx < this.currentIndex ? '#4CAF50' :
                                 idx === this.currentIndex ? '#4E6EF2' : '#E0E0E0')
            })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 4, bottom: 16 })

          // Question content
          Scroll() {
            Column({ space: 16 }) {
              // Question stem
              Text(this.currentQuestion?.stem ?? '')
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
              ForEach(this.currentQuestion?.options ?? [], (option: string, idx: number) => {
                OptionCard({
                  text: option,
                  index: idx,
                  isSelected: this.selectedOption === idx,
                  isCorrect: idx === this.currentQuestion?.correctIndex,
                  showResult: this.showResult,
                  onSelect: () => { this.selectedOption = idx; }
                })
              })

              // Result feedback
              if (this.showResult) {
                Column({ space: 12 }) {
                  ResultBadge({ isCorrect: this.isCorrect })

                  // Explanation
                  Column() {
                    Text('Explanation')
                      .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#4E6EF2')
                    Text(this.currentQuestion?.explanation ?? '')
                      .fontSize(14).fontColor('#333333').lineHeight(22).margin({ top: 8 })
                  }
                  .width('100%')
                  .padding(16)
                  .backgroundColor('#F0F4FF')
                  .borderRadius(12)

                  // Action buttons
                  Row({ space: 12 }) {
                    Button('Ask AI 🤖')
                      .layoutWeight(1).height(44)
                      .backgroundColor('#FF8E53').fontColor('#FFFFFF')
                      .borderRadius(12).fontSize(15)
                      .onClick(() => { this.openAIChat(); })

                    Button(this.currentIndex < this.questions.length - 1 ? 'Next →' : 'Results →')
                      .layoutWeight(1).height(44)
                      .backgroundColor('#4E6EF2').fontColor('#FFFFFF')
                      .borderRadius(12).fontSize(15)
                      .onClick(() => { this.nextQuestion(); })
                  }
                  .width('100%')
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
              }

              // Submit button (before answering)
              if (!this.showResult) {
                Button('Submit Answer')
                  .width('100%').height(48)
                  .backgroundColor(this.selectedOption >= 0 ? '#4E6EF2' : '#CCCCCC')
                  .fontColor('#FFFFFF').fontSize(16).borderRadius(12)
                  .enabled(this.selectedOption >= 0)
                  .onClick(() => { this.submitAnswer(); })
              }
            }
            .padding({ left: 20, right: 20, bottom: 40 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .width('100%').height('100%').backgroundColor('#F5F5F5')

        // Chat Panel (half-modal)
        if (this.showChatPanel) {
          Column() {
            // Dimmed background
            Column()
              .width('100%')
              .layoutWeight(1)
              .backgroundColor('rgba(0,0,0,0.4)')
              .onClick(() => { this.showChatPanel = false; })

            // Chat panel
            Column() {
              // Handle bar
              Column()
                .width(40).height(4).borderRadius(2)
                .backgroundColor('#CCCCCC').margin({ top: 8, bottom: 8 })

              Row() {
                Text('Ask AI Tutor').fontSize(18).fontWeight(FontWeight.Bold)
                Blank()
                Button({ type: ButtonType.Circle }) {
                  Text('✕').fontSize(16).fontColor('#666666')
                }
                .width(32).height(32).backgroundColor('#F0F0F0')
                .onClick(() => { this.showChatPanel = false; })
              }
              .width('100%').padding({ left: 20, right: 20 })

              // Messages
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
                          Text(msg.content + (msg.isStreaming ? '▌' : ''))
                            .fontSize(14).fontColor('#333333').lineHeight(22)
                            .padding(12).backgroundColor('#F5F5F5')
                            .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 4, bottomRight: 12 })
                            .constraintSize({ maxWidth: '80%' })
                          Blank()
                        }.width('100%')
                      }
                    }.padding({ left: 16, right: 16, top: 4, bottom: 4 })
                  }
                })
              }
              .layoutWeight(1)
              .scrollBar(BarState.Off)

              // Input
              Row() {
                TextInput({ placeholder: 'Ask a question...', text: this.chatInput })
                  .layoutWeight(1).height(40).borderRadius(20)
                  .backgroundColor('#F5F5F5').fontSize(14)
                  .onChange((value: string) => { this.chatInput = value; })
                  .onSubmit(() => { this.sendChatMessage(); })

                Button({ type: ButtonType.Circle }) {
                  Text('→').fontSize(18).fontColor('#FFFFFF')
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
