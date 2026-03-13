import { cameraPicker } from '@kit.CameraKit';
import { camera } from '@kit.CameraKit';

@Component
export struct CameraPage {
  @Consume navPathStack: NavPathStack;

  aboutToAppear(): void {
    this.openCamera();
  }

  private async openCamera(): Promise<void> {
    try {
      const pickerProfile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      };
      const result = await cameraPicker.pick(getContext(this),
        [cameraPicker.PickerMediaType.PHOTO], pickerProfile);

      if (result && result.resultUri) {
        this.navPathStack.replacePath({
          name: 'PhotoPreviewPage',
          param: result.resultUri
        });
      } else {
        this.navPathStack.pop();
      }
    } catch (e) {
      console.error('Camera error: ' + JSON.stringify(e));
      this.navPathStack.pop();
    }
  }

  build() {
    NavDestination() {
      Column() {
        Text('Opening camera...')
          .fontSize(16)
          .fontColor('#999999')
        LoadingProgress()
          .width(48)
          .height(48)
          .margin({ top: 16 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#000000')
    }
    .hideTitleBar(true)
  }
}
