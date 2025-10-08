import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { promptAction, router } from '@kit.ArkUI';
import { Place } from '../types/Place';
import { placeList } from '../viewmodel/PlaceList';
import { Location } from '../types/Location';
import display from '@ohos.display';

@Entry
@Component
struct Index {

  @State totalPoint: number = 0;
  @State isQuestion: boolean = false;
  @State questionNumber: number = 0;
  @State currentQuestion: Place | null = null;
  @State questions: Place[] = [];

  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;

  @State isGameFinished: boolean = false;
  @State isGameStarted: boolean = false;
  @State selectedLocation: Location| null = null;
  @State showMap: boolean = false;
  @State showFlag: boolean = false;

  private circleDiameter: number = 0
  private circleRadius: number = 0


  aboutToAppear(): void {

    this.circleDiameter = display.getDefaultDisplaySync().width/2
    this.circleRadius = this.circleDiameter / 2;

    const params = router.getParams() as mapCommon.MapOptions
    if(params) {
      this.mapOptions = params
    }

    this.setQuestions()

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        let callback = () => {
          //console.info(this.TAG, `on-mapLoad`);
          this.addMapClickListener();
        }
        this.mapEventManager.on("mapLoad", callback);
      } else {
        console.error(`Failed to initialize the map. Code: ${err.code}; message: ${err.message}`);
      }
    };
  }


  private startGame () {
    this.isGameStarted = true;
    this.totalPoint = 0;
    this.questionNumber = 1;
    this.currentQuestion = this.questions[0];
    this.playGame();
  }

  private setQuestions () {
    const timestamp = Date.now();
    const randomNumber = timestamp % 20;

    for(let i = randomNumber; i< randomNumber + 10; i++) {
      this.questions.push(placeList[i])
    }
  }

  private playGame () {
    if(this.questionNumber > 10) {
      this.isGameFinished = true;
      this.isGameStarted = false;
      return;
    }

    this.showFlag = true;
    setTimeout(() => {
      this.showMap = true;
      this.showFlag = false;
    }, 5000);
  }

  private checkAnswer(selectedLocation: Location, currentQuestion: Place) {

    const isCorrect =
      selectedLocation.latitude <= currentQuestion.maxLatitude &&
        selectedLocation.latitude >= currentQuestion.minLatitude &&
        selectedLocation.longitude <= currentQuestion.maxLongitude &&
        selectedLocation.longitude >= currentQuestion.minLongitude;

    if(isCorrect) {
      this.totalPoint += 10;
      promptAction.showToast({
        message: '✅ Correct Answer! +10 point',
        duration: 1000,
      });
    } else {
      promptAction.showToast({
        message: '❌ Wrong!',
        duration: 1000,
      });
    }

    this.questionNumber += 1;
    if(this.questionNumber <= 10) {
      this.currentQuestion = this.questions[this.questionNumber - 1];
      this.playGame();
    } else {
      this.isGameFinished = true;
    }
  }

  private restartGame() {
    this.isGameFinished = false;
    this.isGameStarted = false;
    this.questionNumber = 0;
    this.totalPoint = 0;
    this.currentQuestion = null;
    this.selectedLocation = null;
    this.questions = [];
    this.setQuestions();

  }

  private addMapClickListener(): void {
    if (!this.mapEventManager) return;

    let callback = (position: mapCommon.LatLng) => {
      console.info("mapClick", `Latitude: ${position.latitude}, Longitude: ${position.longitude}`);

      this.selectedLocation = {
        latitude: position.latitude,
        longitude: position.longitude
      };

      this.checkAnswer(this.selectedLocation, this.currentQuestion!);
    };

    this.mapEventManager.on("mapClick", callback);
  }


  build() {
    Column() {

      if(!this.isGameStarted && !this.isGameFinished) {
        this.buildStartScreen()
      }

      else if(this.isGameFinished) {
        this.buildResultScreen()
      }

      else if(this.showFlag) {
        this.buildQuestionScreen(this.currentQuestion!)
      }

      else if(this.showMap) {
        this.buildMapScreen()
      }
    }
    .height('100%')
    .width('100%')
  }

  @Builder
  buildResultScreen() {
    Stack() {
      Circle()
        .width(this.circleDiameter)
        .height(this.circleDiameter)
        .fill(Color.Transparent)
        .stroke(Color.Brown)
        .strokeWidth(20)
      Column() {
        Text(`${this.totalPoint} / 100`)
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ bottom: 10 })

        Button('Retry')
          .fontSize(20)
          .fontColor(Color.White)
          .backgroundColor(Color.Orange)
          .padding(10)
          .borderRadius(20)
          .onClick(() => {
            this.restartGame()
          })
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1a1a1a')
  }

  @Builder
  buildMapScreen() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%')
    }.height('100%')
  }

  @Builder
  buildQuestionScreen(place: Place) {
    Stack() {
      Image(place.image)
        .width(this.circleDiameter)
        .height(this.circleDiameter)
        .objectFit(ImageFit.Cover)
        .borderRadius(this.circleDiameter / 2)
        .clip(new Circle({ width: this.circleDiameter, height: this.circleDiameter }))
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildStartScreen() {
    Stack() {
      Circle()
        .width(this.circleDiameter)
        .height(this.circleDiameter)
        .fill(Color.Transparent)
        .stroke(Color.Brown)
        .strokeWidth(20)

      Text('START')
        .fontSize(46)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .fontStyle(FontStyle.Italic)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.startGame();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1a1a1a')
  }
}