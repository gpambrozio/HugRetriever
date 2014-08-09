//
//  HRViewController.m
//  HugRetriever
//
//  Created by Gustavo Ambrozio on 8/8/14.
//  Copyright (c) 2014 Gustavo Ambrozio. All rights reserved.
//

#import "HRViewController.h"

#import "PTDBeanRadioConfig.h"

@interface HRViewController ()

// how we access the beans
@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (nonatomic, strong) PTDBean *bean;

@property (weak, nonatomic) IBOutlet UILabel *lblBattery;
@property (weak, nonatomic) IBOutlet UILabel *lblCount;
@property (weak, nonatomic) IBOutlet UILabel *lblAnalog;
@property (weak, nonatomic) IBOutlet UILabel *lblAverage;

@end

@implementation HRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // instantiating the bean starts a scan. make sure you have you delegates implemented
    // to receive bean info
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
}

#pragma mark - BeanManagerDelegate Callbacks

- (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
    if(self.beanManager.state == BeanManagerState_PoweredOn){
        [self.beanManager startScanningForBeans_error:nil];
    }
    else if (self.beanManager.state == BeanManagerState_PoweredOff) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Turn on bluetooth to continue"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
    self.bean = bean;
    self.bean.delegate = self;
    [self.beanManager connectToBean:self.bean error:nil];
}

- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }

    [self.beanManager stopScanningForBeans_error:&error];
    [self.bean readBatteryVoltage];
    [self.bean readScratchBank:1];
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Ok", nil];
        [alert show];
    }
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error{

}

#pragma mark BeanDelegate

-(void)bean:(PTDBean*)device error:(NSError*)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    [alert show];
}

-(void)bean:(PTDBean*)device receivedMessage:(NSData*)data {

}

-(void)bean:(PTDBean*)bean didUpdateAccelerationAxes:(PTDAcceleration)acceleration {

}

-(void)bean:(PTDBean *)bean didUpdateLoopbackPayload:(NSData *)payload {

}

-(void)bean:(PTDBean *)bean didUpdateLedColor:(UIColor *)color {

}

-(void)bean:(PTDBean *)bean didUpdatePairingPin:(UInt16)pinCode {

}

-(void)bean:(PTDBean *)bean didUpdateTemperature:(NSNumber *)degrees_celsius {

}

-(void)bean:(PTDBean*)bean didUpdateRadioConfig:(PTDBeanRadioConfig*)config {

}

-(void)bean:(PTDBean *)bean didUpdateScratchNumber:(NSNumber *)number withValue:(NSData *)data {
    Byte *bytes = (Byte *)data.bytes;
    switch (number.intValue) {
        case 1:     // count
        {
            uint16_t count = bytes[0] + (bytes[1] << 8);
            uint32_t sensorHistoryAvg = bytes[2] + (bytes[3] << 8) + (bytes[4] << 16) + (bytes[5] << 24);
            uint16_t sensorValue = bytes[6] + (bytes[7] << 8);
            _lblCount.text = [NSString stringWithFormat:@"%d", count];
            _lblAnalog.text = [NSString stringWithFormat:@"%d", sensorValue];
            _lblAverage.text = [NSString stringWithFormat:@"%d", sensorHistoryAvg];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.bean readScratchBank:1];
            });
            break;
        }

        default:
            break;
    }
}

- (void)beanDidUpdateBatteryVoltage:(PTDBean *)bean error:(NSError *)error {
    _lblBattery.text = [NSString stringWithFormat:@"%.2fV", bean.batteryVoltage.doubleValue];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.bean readBatteryVoltage];
    });
}

- (void)bean:(PTDBean *)bean serialDataReceived:(NSData *)data {
    NSLog(@"Received serial %@", data);
}

@end
