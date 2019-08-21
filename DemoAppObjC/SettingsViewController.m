//
//  SettingsViewController.m
//  DemoAppObjC
//
//  Created by Travis Prescott on 8/9/19.
//  Copyright © 2019 Travis Prescott. All rights reserved.
//

#import "ColorUtil.h"
#import "DemoAppObjC-Swift.h"
#import "MSColorSelectionViewController.h"
#import "SettingsViewController.h"

@interface SettingsViewController () <UIPopoverPresentationControllerDelegate, MSColorSelectionViewControllerDelegate> {
    NSString *appConfigConnectionString;
    
    NSNumber *lowSentimentThreshold;
    NSNumber *highSentimentThreshold;
    UIColor *lowSentimentColor;
    UIColor *neutralSentimentColor;
    UIColor *highSentimentColor;
    
    NSMutableDictionary *appConfigSettings;
    UIButton *selectedColorButton;
}

@property (weak, nonatomic) IBOutlet UISlider *lowSentimentSlider;
@property (weak, nonatomic) IBOutlet UISlider *highSentimentSlider;
@property (weak, nonatomic) IBOutlet UILabel *lowSentimentLabel;
@property (weak, nonatomic) IBOutlet UILabel *highSentimentLabel;
@property (weak, nonatomic) IBOutlet UIButton *lowSentimentColorView;
@property (weak, nonatomic) IBOutlet UIButton *neutralSentimentColorView;
@property (weak, nonatomic) IBOutlet UIButton *highSentimentColorView;

@end


@implementation SettingsViewController

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:@"showPopover"]) {
//        UINavigationController *destNav = segue.destinationViewController;
//        destNav.preferredContentSize = [[destNav visibleViewController].view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
//        destNav.popoverPresentationController.delegate = self;
//        MSColorSelectionViewController *controller = (MSColorSelectionViewController *)destNav.visibleViewController;
//        controller.delegate = self;
//        controller.color = self.view.backgroundColor;
//
//        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
//            UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissColorPicker:)];
//            controller.navigationItem.rightBarButtonItem = doneButton;
//        }
//    }
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    appConfigConnectionString = @"Endpoint=https://tjpappconfig.azconfig.io;Id=1-l0-s0:CUEXYNuOJ3AVijq10JBg;Secret=qZS5Ac4e59QHQmaClgEdzjFU46XSklIeXgeSjPq2ONg=";
    [self configureFromAppConfigWithCompletion:^(void) {
        [self performSelectorOnMainThread:@selector(updateWidgets) withObject:nil waitUntilDone:true];
    }];
}

- (void)updateWidgets {
    [_lowSentimentColorView setBackgroundColor: lowSentimentColor];
    [_lowSentimentSlider setValue: lowSentimentThreshold.floatValue];
    [self updateLowSentimentLabel];
    
    [_neutralSentimentColorView setBackgroundColor: neutralSentimentColor];
    [_neutralSentimentColorView setNeedsDisplay];
    
    [_highSentimentColorView setBackgroundColor: highSentimentColor];
    [_highSentimentSlider setValue: highSentimentThreshold.floatValue];
    [self updateHighSentimentLabel];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self isMovingFromParentViewController]) {
        [self updateAppConfigForKey:@"lowSentimentThreshold" withObject:[NSNumber numberWithFloat:_lowSentimentSlider.value]];
        [self updateAppConfigForKey:@"highSentimentThreshold" withObject:[NSNumber numberWithFloat:_highSentimentSlider.value]];
        [self updateAppConfigForKey:@"lowSentimentColor" withObject:_lowSentimentColorView.backgroundColor];
        [self updateAppConfigForKey:@"neutralSentimentColor" withObject:_neutralSentimentColorView.backgroundColor];
        [self updateAppConfigForKey:@"highSentimentColor" withObject:_highSentimentColorView.backgroundColor];
    }
}

- (void)updateAppConfigForKey:(NSString *)key withObject:(id)obj {
    ConfigurationSetting *setting = [appConfigSettings objectForKey:key];
    if ([obj isKindOfClass:[NSNumber class]]) {
        NSNumber *value = (NSNumber *)obj;
        if (value.floatValue == [setting.value floatValue]) {
            // return without doing anything
            return;
        } else {
            setting.value = [NSString stringWithFormat:@"%.02f", value.floatValue];
        }
    } else if ([obj isKindOfClass:[UIColor class]]) {
        UIColor *value = (UIColor *)obj;
        NSString *colorString = [ColorUtil hexStringFromColor:value];
        if (colorString == setting.value) {
            // return without doing anything
            return;
        } else {
            setting.value = colorString;
        }
    }
    ConfigurationSettingPutParameters *params = [[ConfigurationSettingPutParameters alloc] initWithConfigurationSetting:setting];
    [AppConfigurationClient.shared setWithParameters:params forKey:key forLabel:@"DemoApp" completion:nil];
}

- (void)configureFromAppConfigWithCompletion:(void(^)(void))completion {
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
            [settingsDict setValue:setting forKey:setting.key];
        }
        self->lowSentimentThreshold = [NSNumber numberWithFloat:[[(ConfigurationSetting *)[settingsDict valueForKey:@"lowSentimentThreshold"] value] floatValue]];
        self->highSentimentThreshold = [NSNumber numberWithFloat:[[(ConfigurationSetting *)[settingsDict valueForKey:@"highSentimentThreshold"] value] floatValue]];
        self->lowSentimentColor = [ColorUtil colorFromHexString:[(ConfigurationSetting *)[settingsDict valueForKey:@"lowSentimentColor"] value]];
        self->neutralSentimentColor = [ColorUtil colorFromHexString:[(ConfigurationSetting *)[settingsDict valueForKey:@"neutralSentimentColor"] value]];
        self->highSentimentColor = [ColorUtil colorFromHexString:[(ConfigurationSetting *)[settingsDict valueForKey:@"highSentimentColor"] value]];
        self->appConfigSettings = settingsDict;
        completion();
    }];
}

- (void)updateLowSentimentLabel {
    [_lowSentimentLabel setText: [NSString stringWithFormat:@"%.2f", lowSentimentThreshold.doubleValue]];
}

- (IBAction)lowSentimentDidChange:(id)sender {
    float newValue = [(UISlider *)sender value];
    float highValue = highSentimentThreshold.floatValue;
    if (newValue >= highValue) {
        [(UISlider *)sender setValue: highValue - 0.01];
    } else {
        lowSentimentThreshold = [NSNumber numberWithFloat:[(UISlider *)sender value]];
        [self updateLowSentimentLabel];
    }
}

- (void)updateHighSentimentLabel {
    [_highSentimentLabel setText: [NSString stringWithFormat:@"%.2f", highSentimentThreshold.doubleValue]];
}

- (IBAction)highSentimentDidChange:(id)sender {
    float newValue = [(UISlider *)sender value];
    highSentimentThreshold = [NSNumber numberWithFloat:[(UISlider *)sender value]];
    float lowValue = lowSentimentThreshold.floatValue;
    if (newValue <= lowValue) {
        [(UISlider *)sender setValue: lowValue + 0.01];
    } else {
        highSentimentThreshold = [NSNumber numberWithFloat:[(UISlider *)sender value]];
        [self updateHighSentimentLabel];
    }
}

- (IBAction)didTapColorPicker:(UIButton *)sender {
    MSColorSelectionViewController *controller = [[MSColorSelectionViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    navController.modalPresentationStyle = UIModalPresentationPopover;
    navController.popoverPresentationController.delegate = self;
    navController.popoverPresentationController.sourceView = sender;
    navController.popoverPresentationController.sourceRect = sender.bounds;
    navController.preferredContentSize = [controller.view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    controller.delegate = self;
    controller.color = sender.backgroundColor;
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissColorPicker:)];
        controller.navigationItem.rightBarButtonItem = doneButton;
    }
    self->selectedColorButton = sender;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)colorViewController:(MSColorSelectionViewController *)controller didChangeColor:(UIColor *)color {
    self->selectedColorButton.backgroundColor = color;
}

- (void)dismissColorPicker:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        self->selectedColorButton = nil;
    }];
}

@end
