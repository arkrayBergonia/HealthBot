//
//  AVInputViewController.m
//  HealthNAVI
//
//  Created by Francis Jemuel Bergonia on 11/11/19.
//  Copyright © 2019 Arkray Marketing, Inc. All rights reserved.
//

#import "AVInputViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>

#define singleNumArray [NSArray arrayWithObjects: NSLocalizedString(@"singleNum1", nil), NSLocalizedString(@"singleNum2", nil), NSLocalizedString(@"singleNum3", nil), NSLocalizedString(@"singleNum4", nil), NSLocalizedString(@"singleNum5", nil), NSLocalizedString(@"singleNum6", nil), NSLocalizedString(@"singleNum7", nil), NSLocalizedString(@"singleNum8", nil),NSLocalizedString(@"singleNum9", nil), nil]

#define singleNumDict @{NSLocalizedString(@"singleNum1", nil): @"1", NSLocalizedString(@"singleNum2", nil): @"2", NSLocalizedString(@"singleNum3", nil): @"3", NSLocalizedString(@"singleNum4", nil): @"4", NSLocalizedString(@"singleNum5", nil): @"5", NSLocalizedString(@"singleNum6", nil): @"6", NSLocalizedString(@"singleNum7", nil): @"7", NSLocalizedString(@"singleNum8", nil): @"8", NSLocalizedString(@"singleNum9", nil): @"9"}

#define voiceCmdArray [NSArray arrayWithObjects: NSLocalizedString(@"Yes_Btn", nil), NSLocalizedString(@"Cancel_Btn", nil), NSLocalizedString(@"No_Btn", nil), nil]

@interface AVInputViewController () <AVSpeechSynthesizerDelegate>
// AVAudio elements
@property (strong,nonatomic) AVAudioSession * audioSession;
@property (strong, nonatomic) SFSpeechAudioBufferRecognitionRequest * speechRequest;
@property (strong, nonatomic) SFSpeechRecognizer * recognizer;
@property (strong, nonatomic) AVAudioEngine * audioEngine;

// Storyboard elements
@property (weak, nonatomic) IBOutlet UIView *alertBoxView;
@property (weak, nonatomic) IBOutlet UILabel *instructionLabel;
@property (weak, nonatomic) IBOutlet UILabel *inputValue;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtnOutlet;
@property (weak, nonatomic) IBOutlet UIView *mainSubView;

// variables and constants
@property (weak, nonatomic) NSString *inputValueText;
@property (weak, nonatomic) NSString *langCode;

//AVSpeechSynthesizerDelegate
@property (strong, nonatomic) AVSpeechSynthesizer *synthesizer;

@end

@implementation AVInputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    self.synthesizer.delegate = self;
    self.instructionLabel.text = NSLocalizedString(@"instructionConfirmation1", nil);
    self.inputValueText =  @"- - - mg/dL";
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // ユーザーの応答を取得するために、音声認識を開始します。第一は：後、ユーザーに口頭で指示を再生します || 1st: Play verbal instruction to user, AFTER: Start speech recognition to get user response
    [self textToSpeechProcessor:self.instructionLabel.text];
}


-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 出口でaudioEngineを停止 || Stop audioEngine at exit
    [self stopSpeechBtn];
}

//==========================================================================
// 音声認識方法 (ユーザーからの口頭での応答を解釈します) || Speech Recognition methods (Interpret verbal response from user)
//==========================================================================

- (void)speechRecognizerSetup{
    // ユーザーにPersmissionをリクエスト || Request Persmission to user
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        NSLog(@"Request Speech Recognized permission: %@", status == SFSpeechRecognizerAuthorizationStatusAuthorized ? @"authorized" : @"not authorized");
    }];
    
    // SFSpeechRecognizer使用のためにaudioSessionを設定し、 || Set speech recognition parameters & sets audioSession for SFSpeechRecognizer usage
    [self.audioSession setCategory:AVAudioSessionCategoryRecord mode:AVAudioSessionModeMeasurement options:AVAudioSessionCategoryOptionDuckOthers error:nil];
    [self.audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}


// startSpeechRecognition
- (void)startSpeechBtn {
    NSLog(@"***Start Speaking");
    [self speechRecognizerSetup];
    self.speechRequest = nil;
    [self.recognizer recognitionTaskWithRequest:self.speechRequest delegate:self];
    __weak typeof(self) weakSelf = self;
    AVAudioFormat *recordingFormat = [[self.audioEngine inputNode] outputFormatForBus:0];
    [[self.audioEngine inputNode] installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.speechRequest appendAudioPCMBuffer:buffer];
        NSLog(@"***Processing Speech");
    }];
    
    [self.audioEngine prepare];
    NSError *error = nil;
    if (![self.audioEngine startAndReturnError:&error]) {
        NSLog(@"%@",error.userInfo);
    };
    
}

// stopSpeechRecognition
- (void)stopSpeechBtn {
    NSLog(@"***Stop Speaking");
    [self releaseEngine];
    [self.speechRequest endAudio];
}

- (void)releaseEngine{
    NSLog(@"***Speech engine stopped");
    [[self.audioEngine inputNode] removeTapOnBus:0];
    [self.audioEngine stop];
}

//---------------------------------------------------------------------------------------------------------

- (IBAction)cancelBtnTapped:(id)sender {
    [self dismissVCwithResponse:NSLocalizedString(@"cancelConfirmation1", nil)];
}

//==========================================================================
// 音声認識からのテキスト値にスピーチを検証 || Validate Speech to Text value from Speech Recognition
//==========================================================================
- (BOOL)processTranscription: (NSString *)transcription
{ // 最初の転写が数またはYES / NOのように有効で受け取った場合、このメソッドは、検証します。 || this method validates if the initial transcription received is valid like number or YES / NO.
    [self stopSpeechBtn];
    NSLog(@"processTranscriptionText: %@", transcription);
    if (transcription.length <= 3 && [transcription rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) {
        return YES;
    } else if ([voiceCmdArray containsObject:transcription]) {
        return YES;
    } else if ([singleNumArray containsObject:transcription]) {
        return YES;
    } else if ([transcription isEqual: @"- - - mg/dL"] || transcription.length > 3) {
        NSLog(@"SpeechSynthesizer: transcription isEqual: - - - mg/dL OR transcription.length > 3");
        [self speechRecognizerSetup];
        [self startSpeechBtn];
        return NO;
    }
    return NO;
}

- (NSString *)setTranscriptionText: (NSString *)transcription
{   // この方法は、文字列として返され、最終的な転写に基づいて適切なアクションをユーザから受信したトリガ || this method returns as string and trigger an appropriate action based from the final transcription received from the user
    NSLog(@"setTranscriptionText: %@", transcription);
    if (transcription.length <= 3 && [transcription rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) {
        [self setInstructionAndRestartCapture:NSLocalizedString(@"instructionConfirmation2", nil)];
        self.inputValueText = transcription;
        return [NSString stringWithFormat:@"%@ mg/dL", transcription];
    } else if ([transcription isEqual: NSLocalizedString(@"Yes_Btn", nil)]) {
        [self itemPassBackProcessor:self.inputValueText];
        return @"- - - mg/dL";
    } else if ([transcription  isEqual: NSLocalizedString(@"No_Btn", nil)]) {
        [self setInstructionAndRestartCapture:NSLocalizedString(@"instructionConfirmation1", nil)];
        return @"- - - mg/dL";
    } else if ([transcription isEqual: NSLocalizedString(@"Cancel_Btn", nil)]) {
        [self dismissVCwithResponse:NSLocalizedString(@"cancelConfirmation1", nil)];
        return @"- - - mg/dL";
    } else if ([singleNumArray containsObject:transcription]) {
        [self setInstructionAndRestartCapture:NSLocalizedString(@"instructionConfirmation2", nil)];
        NSString *singleNum = [singleNumDict objectForKey:transcription];
        NSString *pureNumbers = [[singleNum componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
        self.inputValueText = pureNumbers;
        return [NSString stringWithFormat:@"%@ mg/dL", self.inputValueText];
    }
    [self setInstructionAndRestartCapture:NSLocalizedString(@"instructionConfirmation1", nil)];
    return @"- - - mg/dL";
}

-(void)setInstructionAndRestartCapture: (NSString *)instructionText
{   // スピーチへのテキストは、有効入力グルコースプロセスを再起動します || Text to Speech activated then restart input glucose process
    self.instructionLabel.text = instructionText;
    [self textToSpeechProcessor:self.instructionLabel.text];
}


// 最終であることをユーザに確認場合戻る選択したアイテムを渡します || Pass Back selected item if confirmed by user to be final
-(void)itemPassBackProcessor: (NSString *)itemInput
{
    if ([itemInput isEqual: @"- - - mg/dL"]) {
        [self textToSpeechProcessor:NSLocalizedString(@"reviewGlucoseResponse1", nil)];
    } else if (itemInput.length <= 3 && [itemInput rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) {
        [self.passBackdelegate addItemViewController:self didFinishEnteringItem:itemInput];
        [self dismissVCwithResponse:NSLocalizedString(@"saveConfirmation1", nil)];
        NSLog(@"***itemPassBackProcessor PASSED");
    } else {
        [self textToSpeechProcessor:NSLocalizedString(@"reviewGlucoseResponse1", nil)];
    }
}

-(void)dismissVCwithResponse: (NSString *)response
{   // スピーチへのテキストは、ビューコントローラを閉じ活性化 || Text to Speech activated then dismiss view controller
    [self textToSpeechProcessor:response];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//==========================================================================
// スピーチプロセッサにテキスト (ユーザーに口頭で指示を与えます) || Text To Speech Processor (Give verbal instructions to users)
//==========================================================================

-(void)textToSpeechProcessor: (NSString *)transcription
{
    //textToSpeechProcessor使用のためにaudioSessionをリセット || resets audioSession for textToSpeechProcessor usage
    self.audioSession = [AVAudioSession sharedInstance];
    [self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [self.audioSession setMode:AVAudioSessionModeDefault error:nil];
    
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:transcription];
    NSString *langCode = [[NSLocale currentLocale] languageCode];
    NSLog(@"*** textToSpeechProcessor - langCode: %@", langCode);
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:langCode];
    [self.synthesizer speakUtterance:utterance];
    
}

#pragma mark - SFSpeechRecognizerDelegate
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    if (available) {
        NSLog(@"***Recording request becomes ACTIVE");
    } else {
        NSLog(@"***Recording request becomes INACTIVE");
    }
    
}

//==========================================================================
// Speech Recognition Delegates
//==========================================================================

#pragma mark - SFSpeechRecognitionTaskDelegate

- (void)speechRecognitionDidDetectSpeech:(SFSpeechRecognitionTask *)task{
    NSLog(@"***Speech Recognition detect speech / voice");
}


- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didHypothesizeTranscription:(SFTranscription *)transcription{
    NSLog(@"***called during Speech Recognition, %@",transcription.formattedString);
    BOOL *speechValid = [self processTranscription:transcription.formattedString];
    if (speechValid) { // 最初の転写を検証する場合は許容できるかどうか || validate initial transcription if acceptable or not
        self.inputValue.text = transcription.formattedString;
    }
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult{
    NSLog(@"***Speech Recognition - Final Phase: %@", recognitionResult.bestTranscription.formattedString);
    
    BOOL *speechValid = [self processTranscription:recognitionResult.bestTranscription.formattedString];
    if (speechValid) { // 再検証 || validate again
        self.inputValue.text = [self setTranscriptionText:recognitionResult.bestTranscription.formattedString];
    }
}

- (void)speechRecognitionTaskFinishedReadingAudio:(SFSpeechRecognitionTask *)task{
    NSLog(@"***Speech Recognition completed");
}

- (void)speechRecognitionTaskWasCancelled:(SFSpeechRecognitionTask *)task{
    NSLog(@"***Speech Recognition cancelled");
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishSuccessfully:(BOOL)successfully{
    if (successfully){
        NSLog(@"***The Speech Recognition process ends with no errors.");
    }
    else {
        NSLog(@"***The Speech Recognition process is over, there is a an error.");
    }
    // これはaudioEngineの安定性や状態を監視するように設定しました || this was set to monitor stability or state of audioEngine
    if ([self.audioEngine isRunning]) {
        NSLog(@"***The Speech Recognition - audioEngine isRunning");
    } else {
        NSLog(@"***The Speech Recognition - audioEngine isNOT Running");
    }
    
    if (self.audioSession != nil) {
        NSLog(@"***The Speech Recognition - audioSession !=nil");
    } else {
        NSLog(@"***The Speech Recognition - audioSession is nil");
    }
    
    NSLog(@"speechRecognitionTask FIN:inputValueText: %@", self.inputValueText);
    
}

#pragma mark - getting & setting

- (AVAudioSession *)audioSession{
    if (_audioSession == nil) {
        _audioSession = [AVAudioSession sharedInstance];
    }
    return _audioSession;
}

- (SFSpeechAudioBufferRecognitionRequest *)speechRequest{
    if (_speechRequest == nil) {
        _speechRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        _speechRequest.shouldReportPartialResults = YES;
    }
    return _speechRequest;
}

- (SFSpeechRecognizer *)recognizer{
    if (_recognizer == nil) {
        _recognizer = [[SFSpeechRecognizer alloc] init];
        // Set the language based on Local
        NSString *langCode = [[NSLocale currentLocale] languageCode];
        NSLog(@"*** SFSpeechRecognizer - langCode: %@", langCode);
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:langCode];
        _recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
        _recognizer.delegate = self;
    }
    return _recognizer;
}

- (AVAudioEngine *)audioEngine{
    if (_audioEngine == nil) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}

#pragma mark - AVSpeechSynthesizerDelegate

// スピーチへのテキストが開始された場合、このメソッドが呼び出されます || This method is called if Text to Speech started
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance{
    self.cancelBtnOutlet.enabled = NO; // 使用されている間AudioEngineの問題を回避するために、ボタンを無効にします || disable button to avoid issue with AudioEngine while being used
    NSLog(@"SpeechSynthesizer: didStartSpeechUtterance");
}

// スピーチへのテキストが終了した場合、このメソッドが呼び出されます || This method is called if Text to Speech finished
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance{
    self.cancelBtnOutlet.enabled = YES;
    // ユーザーの音声入力や応答を取得するために、音声認識を開始 || start speech recognizer to get user voice input or response
    dispatch_async(dispatch_get_main_queue(), ^{
        [self speechRecognizerSetup];
        [self startSpeechBtn];
    });
    NSLog(@"SpeechSynthesizer: didFinishSpeechUtterance");
}

@end

