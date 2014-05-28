//
//  ViewController.m
//  MeasureTest
//
//  Created by Nino Tokuda on 5/15/14.
//  Copyright (c) 2014 Nino Tokuda. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>

@interface ViewController ()

@property (strong,nonatomic) CMMotionManager *cmmanager;


@property (weak, nonatomic) IBOutlet UIProgressView *xpv;

@property (weak, nonatomic) IBOutlet UIProgressView *ypv;

@property (weak, nonatomic) IBOutlet UIProgressView *zpv;

@property (weak, nonatomic) IBOutlet UILabel *distLabel;

@property (weak, nonatomic) IBOutlet UILabel *speedLabel;


@property (weak, nonatomic) IBOutlet UILabel *counterLabel;
@property (weak, nonatomic) IBOutlet UILabel *strengthLabel;



@property (nonatomic) float xPos;
@property (nonatomic) float yPos;
@property (nonatomic) float zPos;

@property (nonatomic) float xMov;
@property (nonatomic) float yMov;
@property (nonatomic) float zMov;

@property (nonatomic) float xVel;
@property (nonatomic) float yVel;
@property (nonatomic) float zVel;

@property (nonatomic) float xDist;
@property (nonatomic) float yDist;
@property (nonatomic) float zDist;

@property (nonatomic) float xAcc;
@property (nonatomic) float yAcc;
@property (nonatomic) float zAcc;

@property (nonatomic) float xPastAcc;
@property (nonatomic) float yPastAcc;
@property (nonatomic) float zPastAcc;


@property (nonatomic) float time;

@property (nonatomic) float back1;
@property (nonatomic) float back2;
@property (nonatomic) float back3;
@property (nonatomic) float localHight;

@property (nonatomic) int counter;
@property (nonatomic) float lastPunchStrength;
@property (nonatomic) BOOL initiated;

@property (nonatomic, strong) NSMutableArray *measureArray;
@property (nonatomic, strong) NSMutableArray *peakArray;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

  self.xPos = 0.0;
  self.yPos = 0.0;
  self.zPos = 0.0;

  self.xMov = 0.0;
  self.yMov = 0.0;
  self.zMov = 0.0;

  self.xVel = 0.0;
  self.yVel = 0.0;
  self.zVel = 0.0;

  self.xDist = 0.0;
  self.yDist = 0.0;
  self.zDist = 0.0;

  self.xAcc = 0.0;
  self.yAcc = 0.0;
  self.zAcc = 0.0;

  self.xPastAcc = 0.0;
  self.yPastAcc = 0.0;
  self.zPastAcc = 0.0;


  self.time = 0.0;


  // new properties

  self.back1 = 0.0;
  self.back2 = 0.0;
  self.back3 = 0.0;
  self.localHight = 0.0;
  self.counter = 0;
  self.lastPunchStrength = 0.0;
  self.measureArray = [NSMutableArray array];
  self.peakArray = [NSMutableArray array];


  self.initiated = NO;


  self.cmmanager = [[CMMotionManager alloc] init];

  float acc_interval = 1.0 / 30.0;
  self.cmmanager.accelerometerUpdateInterval = acc_interval;
  [self.cmmanager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
    if(!error){

      //NSLog(@"%@", accelerometerData);

    }else{
      NSLog(@"error %@", error.userInfo);
    }
  }];

  self.cmmanager.gyroUpdateInterval = acc_interval;
  [self.cmmanager startGyroUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMGyroData *gyroData, NSError *error) {

    if(!error){
     // NSLog(@"gyro %@", gyroData);
    }

  }];


  self.cmmanager.deviceMotionUpdateInterval = acc_interval;
  [self.cmmanager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {

    if(!error && motion){


      CMAcceleration acceleration = motion.userAcceleration;



      if(!self.initiated){

        self.initiated = YES;
        self.time = motion.timestamp;
        self.xPastAcc = acceleration.x;
        self.yPastAcc = acceleration.y;
        self.zPastAcc = acceleration.z;

        self.xAcc = 0.0;
        self.yAcc = 0.0;
        self.zAcc = 0.0;

        return;
      }


      if(abs(acceleration.y) > 1.0) NSLog(@"*******");
      NSLog(@"%f", acceleration.y);



      // ------ detect punch ----- //
      float thresh = 6.0;

      // calculate distance for 4 measurements
      float overal_min = MIN(MIN(self.back1, self.back2), MIN(self.back3, acceleration.y));
      float overal_max = MAX(MAX(self.back1, self.back2), MAX(self.back3, acceleration.y));
      float overal_distance = overal_max - overal_min;

      if(abs(overal_distance) > thresh){

        if(abs(overal_distance) > self.localHight) self.localHight = abs(overal_distance);

      }else{
        if(self.localHight > 0.0) NSLog(@"punch"), self.counter++, [self.peakArray addObject:@(acceleration.y)], self.lastPunchStrength = self.localHight;
        self.counterLabel.text = [NSString stringWithFormat:@"%i", self.counter];
        self.strengthLabel.text = [NSString stringWithFormat:@"%f", self.lastPunchStrength];
        self.localHight = 0.0;

      }

      self.back1 = self.back2;
      self.back2 = self.back3;
      self.back3 = acceleration.y;
      //[self.measureArray addObject:@(acceleration.y)];


      //NSLog(@"%f  %f   %f ", acceleration.x, acceleration.y, acceleration.z);


      float time_diff = motion.timestamp - self.time;
      self.time = motion.timestamp;


      float filterFactor = 0.3;

      // ********** x pos ********** //
      //float xCurrentAcc = acceleration.x - ((acceleration.x * 0.1) + (self.xPastAcc * 0.9));
      float xCurrentAcc = acceleration.x;
      //float xCurrentAcc = (acceleration.x * filterFactor) + (self.xPastAcc * (1.0 - filterFactor));
      float xVelocity = pow(xCurrentAcc,2) / 2;
      self.xVel = xVelocity;
      self.xPastAcc = acceleration.x;
      float xDistance = xVelocity * time_diff + abs(xCurrentAcc) * pow(time_diff,2) / 2;
      if(xCurrentAcc >=0) self.xPos += xDistance;
      else self.xPos -= xDistance;


      // ********** y pos ********** //
      //float yCurrentAcc = acceleration.y - ((acceleration.y * 0.1) + (self.yPastAcc * 0.9));
      float yCurrentAcc = acceleration.y;
      float yVelocity = pow(yCurrentAcc,2) / 2;
      self.yVel = yVelocity;
      self.yPastAcc = acceleration.y;
      float yDistance = yVelocity * time_diff + abs(yCurrentAcc) * pow(time_diff,2) / 2;
      if(yCurrentAcc >=0) self.yPos += yDistance;
      else self.yPos -= yDistance;


      // ********** z pos ********** //
      float zCurrentAcc = acceleration.z - ((acceleration.z * 0.1) + (self.zPastAcc * 0.9));
      float zVelocity = pow(zCurrentAcc,2) / 2;
      self.zVel = zVelocity;
      self.zPastAcc = acceleration.z;
      float zDistance = zVelocity * time_diff + zCurrentAcc * pow(time_diff,2) / 2;
      if(zCurrentAcc >=0) self.zPos += zDistance;
      else self.zPos -= zDistance;


      float total_distance = sqrtf(sqrtf(powf(self.xPos, 2) + powf(self.yPos, 2)) + powf(self.zPos,2));

     // NSLog(@"****************************************");

      //NSLog(@"vel %f acc %f",xVelocity, xCurrentAcc);

      //NSLog(@"%f", self.xVel);


      self.distLabel.text = [NSString stringWithFormat:@"%f", self.xPos];

      self.speedLabel.text = [NSString stringWithFormat:@"%f", self.xVel];


      
    }else{
      NSLog(@"error %@", error);
    }

  }];



}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}







- (IBAction)startButtonPushed:(id)sender {

  [self.measureArray removeAllObjects];
  [self.peakArray removeAllObjects];
  self.counter = 0;
  self.counterLabel.text = @"0";

}


- (IBAction)endButtonPushed:(id)sender {







}


@end
