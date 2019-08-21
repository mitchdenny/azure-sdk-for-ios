//
//  ViewController.m
//  DemoAppObjC
//
//  Created by Travis Prescott on 8/8/19.
//  Copyright © 2019 Travis Prescott. All rights reserved.
//

#import "ColorUtil.h"
#import "MainViewController.h"
#import "DemoAppObjC-Swift.h"
#import <MicrosoftCognitiveServicesSpeech/SPXSpeechApi.h>

@interface MainViewController () {
    NSString *appConfigConnectionString;
    NSString *computerVisionEndpoint;
    NSString *computerVisionKey;
    NSString *speechKey;
    NSString *serviceRegion;
    NSString *textAnalyticsEndpoint;

    NSNumber *lowSentimentThreshold;
    NSNumber *highSentimentThreshold;
    UIColor *lowSentimentColor;
    UIColor *neutralSentimentColor;
    UIColor *highSentimentColor;
}

@property (weak, nonatomic) IBOutlet UIButton *fromMicButton;
@property (weak, nonatomic) IBOutlet UIButton *fromCameraButton;
@property (weak, nonatomic) IBOutlet UILabel *recognitionResultLabel;
@property (weak, nonatomic) IBOutlet UILabel *sentimentLabel;
- (IBAction)fromMicButtonClicked:(UIButton *)sender;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // TODO: Paste your values from the portal
    // Note: this should not be done in a production app, as it is completely insecure!
    appConfigConnectionString = @"";
    computerVisionEndpoint = @"";
    computerVisionKey = @"";
    speechKey = @"";
    serviceRegion = @"";

    // TODO: Re-enable for testing camera
//    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
//        UIAlertController *myAlert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Device has no camera!" preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *buttonOk = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
//        }];
//        [myAlert addAction:buttonOk];
//        [self presentViewController:myAlert animated:YES completion:nil];
//    }
}

- (void)viewDidAppear:(BOOL)animated {
    // update settings from AppConfig
    [self configureFromAppConfig];
    [self updateSentimentLabel:@"" withColor:UIColor.blackColor];
    [self updateRecognitionStatusText:@"Recognition result..."];
}

- (IBAction)fromImageButtonClicked:(UIButton *)sender {
    UIImage *currImage = sender.imageView.image;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [self recognizeFromCamera: currImage];
    });
}

- (IBAction)fromCameraButtonClicked:(UIButton *)sender {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        [self presentViewController:picker animated:YES completion:NULL];
    });
}

- (IBAction)fromMicButtonClicked:(UIButton *)sender {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [self recognizeFromMicrophone];
    });
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        [self recognizeFromCamera:chosenImage];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)configureFromAppConfig {
    NSError *error = nil;
    [AppConfigurationClient.shared configureWithConnectionString:appConfigConnectionString error:&error];
    if (error) {
        NSLog(@"Invalid connection string: %@", appConfigConnectionString);
        return;
    }
    [AppConfigurationClient.shared getConfigurationSettingsForKey:nil forLabel:@"DemoApp" completion:^(NSArray<ConfigurationSetting *> *settings) {
        NSMutableDictionary *settingsDict = [NSMutableDictionary dictionary];
        for (id settingId in [settings objectEnumerator]) {
            ConfigurationSetting *setting = (ConfigurationSetting *)settingId;
            [settingsDict setValue:setting.value forKey:setting.key];
        }
        self->lowSentimentThreshold = [settingsDict valueForKey:@"lowSentimentThreshold"];
        self->highSentimentThreshold = [settingsDict valueForKey:@"highSentimentThreshold"];
        self->lowSentimentColor = [ColorUtil colorFromHexString:[settingsDict valueForKey:@"lowSentimentColor"]];
        self->neutralSentimentColor = [ColorUtil colorFromHexString:[settingsDict valueForKey:@"neutralSentimentColor"]];
        self->highSentimentColor = [ColorUtil colorFromHexString:[settingsDict valueForKey:@"highSentimentColor"]];
    }];
}

- (void)recognizeFromMicrophone {
    SPXSpeechConfiguration *speechConfig = [[SPXSpeechConfiguration alloc] initWithSubscription:speechKey region:serviceRegion];
    if (!speechConfig) {
        NSLog(@"Could not load speech config");
        [self updateRecognitionErrorText:(@"Speech Config Error")];
        return;
    }
    
    [self updateRecognitionStatusText:(@"Recognizing...")];
    
    SPXSpeechRecognizer* speechRecognizer = [[SPXSpeechRecognizer alloc] init:speechConfig];
    if (!speechRecognizer) {
        NSLog(@"Could not create speech recognizer");
        [self updateRecognitionResultLabel:(@"Speech Recognition Error")];
        return;
    }
    
    SPXSpeechRecognitionResult *speechResult = [speechRecognizer recognizeOnce];
    if (SPXResultReason_Canceled == speechResult.reason) {
        SPXCancellationDetails *details = [[SPXCancellationDetails alloc] initFromCanceledRecognitionResult:speechResult];
        NSLog(@"Speech recognition was canceled: %@. Did you pass the correct key/region combination?", details.errorDetails);
        [self updateRecognitionErrorText:([NSString stringWithFormat:@"Canceled: %@", details.errorDetails ])];
    } else if (SPXResultReason_RecognizedSpeech == speechResult.reason) {
        NSLog(@"Speech recognition result received: %@", speechResult.text);
        [self updateRecognitionResultLabel:(speechResult.text)];
    } else {
        NSLog(@"There was an error.");
        [self updateRecognitionErrorText:(@"Speech Recognition Error")];
    }
}

- (void)recognizeFromCamera:(UIImage *) withImage {
    [self updateRecognitionStatusText: @"Analyzing picture..."];
    NSError *error = nil;
    CSComputerVisionClient *client = [[CSComputerVisionClient alloc] initWithEndpoint: computerVisionEndpoint withKey: computerVisionKey withRegion: nil error: &error];
    if (error) {
        NSLog(@"Invalid credentials: %@", computerVisionKey);
        return;
    }
    [client recognizeTextFromImage: withImage withLanguage: @"unk" shouldDetectOrientation: true completion: ^(NSArray <NSString *> *result, NSError *err) {
        [self updateRecognitionResultLabel: [(NSArray<NSString *> *) result componentsJoinedByString:@" "]];
    }];
}

- (void)updateRecognitionResultLabel:(NSString *) resultText {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recognitionResultLabel.textColor = UIColor.blackColor;
        self.recognitionResultLabel.text = resultText;
        NSError *error = nil;
        CSTextAnalyticsClient *client = [[CSTextAnalyticsClient alloc] initWithEndpoint: self->computerVisionEndpoint withKey: self->computerVisionKey withRegion: nil error: &error];
        if (error) {
            NSLog(@"Invalid credentials: %@", self->computerVisionKey);
            return;
        }
        [client getSentimentFromText: resultText withLanauage: @"unk" showStats: false completion: ^(float result, NSError *error) {
            NSString *resultString = [NSString stringWithFormat: @"Sentiment: %.2f", result];
            UIColor *color = self->neutralSentimentColor;
            if (result < self->lowSentimentThreshold.doubleValue) {
                color = self->lowSentimentColor;
            } else if (result > self->highSentimentThreshold.doubleValue) {
                color = self->highSentimentColor;
            }
            NSLog(@"%@", resultString);
            [self updateSentimentLabel: resultString withColor: color];
        }];
    });
}

- (void)updateRecognitionErrorText:(NSString *) errorText {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recognitionResultLabel.textColor = UIColor.redColor;
        self.recognitionResultLabel.text = errorText;
        [self updateSentimentLabel: @"" withColor: UIColor.blackColor];
    });
}

- (void)updateRecognitionStatusText:(NSString *) statusText {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recognitionResultLabel.textColor = UIColor.grayColor;
        self.recognitionResultLabel.text = statusText;
        [self updateSentimentLabel: @"" withColor: UIColor.blackColor];
    });
}

- (void)updateSentimentLabel:(NSString *) text withColor: (UIColor *) color {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (color != nil) {
            self.sentimentLabel.textColor = color;
        }
        self.sentimentLabel.text = text;
    });
}

@end
