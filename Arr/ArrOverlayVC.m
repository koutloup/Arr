/*
 Copyright (C) 2011 Petros Koutloubasis. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ArrOverlayVC.h"
#import "ArrLocation.h"
#import "ArrGeoTools.h"
#import <QuartzCore/QuartzCore.h>

//aspect ratio of the screen
#define CAMERA_TRANSFORM_X 1
#define CAMERA_TRANSFORM_Y 1.24299f
//iphone screen dimensions
#define SCREEN_WIDTH  320
#define SCREEN_HEIGTH 480
//field of view / 2
#define FOV_H 30.4f
#define FOV_V 32.75f
//points per deg = SCREEN / FOV
#define POINTS_PER_DEG_H 7.89f
#define POINTS_PER_DEG_V 9.01f
//label widht
#define LOCATION_LABEL_WIDTH 280.0f
#define LOCATION_LABEL_HEIGTH 34.0f
#define LOCATION_LABEL_GAP 6.0f
//scaling
#define SCALE_MIN_DISTANCE 200.0f //scale = 1
#define SCALE_MAX_DISTANCE 1000.0f //scale = SCALE_MINIMUM
#define SCALE_MINIMUM  0.7f //don't scale smaller
#define SCALE_FACTOR (1 - SCALE_MINIMUM) / (SCALE_MAX_DISTANCE - SCALE_MIN_DISTANCE) 
//other options
#define SHOW_RADAR 1
#define MAX_LOCATIONS 7

@interface ArrOverlayVC()
- (void)createLocationLabel:(ArrLocation*)arrLocation;
- (void)startLocationManager;
- (void)stopLocationManager;
- (void)startMotionManager;
- (void)stopMotionManager;
- (void)initLocations;
- (void)updateLocations;
- (void)updateLocationLabels;
- (void)sortArrLocations;
@end

@implementation ArrOverlayVC

@synthesize delegate;
@synthesize imagePickerController;
@synthesize arrLocations;
@synthesize locLabels;
@synthesize radarPoints;
@synthesize locationManager;
@synthesize motionManager;

- (void)dealloc {
    NSLog(@"deallocating arrVC..");
    [self stopLocationManager];
    [locationManager release];
    
    [self stopMotionManager];
    [motionManager release];
    
    [imagePickerController setDelegate:nil];
    [imagePickerController release];
    [arrLocations release];
    [locLabels release];
    
    NSLog(@"..done!");
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (id)init {
    self = [super init];
    if (self) {
        self.imagePickerController = [[[UIImagePickerController alloc] init] autorelease];
        self.imagePickerController.delegate = self;
        
        self.arrLocations = [[NSMutableArray alloc] init];
        self.locLabels = [[NSMutableArray alloc] init];
        self.radarPoints = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)setupImgPicker {    
    yTransform = 0;
    NSLog(@"setting up img picker..");
    //setup picker
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.showsCameraControls = NO;
	self.imagePickerController.navigationBarHidden = YES;
	self.imagePickerController.toolbarHidden = YES;
    self.imagePickerController.wantsFullScreenLayout = YES;
    self.imagePickerController.cameraViewTransform = 
        CGAffineTransformScale(self.imagePickerController.cameraViewTransform, CAMERA_TRANSFORM_X, CAMERA_TRANSFORM_Y);
    
    self.imagePickerController.view.frame = CGRectMake(0.0, 0.0, 320, 480);
    self.imagePickerController.cameraOverlayView.layer.borderWidth = 1.0;
    
    //fit our view to screen
    self.view.transform = CGAffineTransformMakeRotation(1.570796326794897);
    self.view.frame = CGRectMake(0.0, 0.0, 320.0, 480.0);
    
    //show up
    [self.imagePickerController.cameraOverlayView addSubview:self.view];
    NSLog(@"..done!");
    
    //notify us on orientation changes
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(orientationChanged) 
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
    
    [self startMotionManager];
    [self startLocationManager];
    
    //location manager assumes that the top of the device in portrait mode represents due north (0 degrees) by default
    [self.locationManager setHeadingOrientation:CLDeviceOrientationLandscapeLeft];
    
    //radar-circle
    UIImageView *radarIV = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 82, 82)];
    [radarIV setImage:[UIImage imageNamed:@"ArrRadar"]];
    [self.view addSubview:radarIV];
    [radarIV release];
}

- (void)startRenderLoop {
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateLocationLabels) userInfo:nil repeats:YES];
    [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)orientationChanged {
    if([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
        [timer invalidate];
        [self stopLocationManager];
        [self startMotionManager];
        [self.delegate didFinish];
    }
}

#pragma mark - MotionManager

- (void)startMotionManager {
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager setDeviceMotionUpdateInterval:0.1];
    [self.motionManager startDeviceMotionUpdates];
}

- (void)stopMotionManager {
    [motionManager stopDeviceMotionUpdates];
}

#pragma mark - LocationManager

- (void)startLocationManager {
    NSLog(@"starting locationmanager..");
    //configure
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    //start
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];
    NSLog(@"done!");
}

- (void)stopLocationManager {
    self.locationManager.delegate = nil;
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    if(!oldLocation) {
        [self initLocations];
    } else {
        [self updateLocations];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"! locationManagerError: %@", [error localizedDescription]);
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    return YES;
}

#pragma mark - Augmented

- (void)initLocations {
    [self updateLocations]; //update to get distances
    [self sortArrLocations]; //sort by distances
    //create labels
    int count = 0;
    for(ArrLocation *arrLocation in arrLocations) {
        [self createLocationLabel:arrLocation];
        count++;
        if(count == MAX_LOCATIONS) break;
    }
    //start render
    [self startRenderLoop];
}

//add location to locations and creates label for location
- (void)addLocation:(ArrLocation *)arrLocation {
    [self.arrLocations addObject:arrLocation];
}

//updated bearing and distance of locations
- (void)updateLocations {
    CLLocationCoordinate2D currentCoordinate = self.locationManager.location.coordinate;
    
    ArrLocation *element;
    NSEnumerator *enumerator = [self.arrLocations objectEnumerator];
    while((element = [enumerator nextObject])) {
        element.bearing = [ArrGeoTools degFromCoordinate:currentCoordinate toCoordinate:element.coordinate];
        element.distance = [ArrGeoTools distanceBetweenCoordinate:element.coordinate andCoordinate:currentCoordinate];
    }
}

- (void)updateLocationLabels {
    int roll = (int) 2.63 * ([ArrGeoTools radToDeg:self.motionManager.deviceMotion.attitude.roll] + 90) * -1;
    if (roll != yTransform) yTransform = yTransform + ((roll - yTransform) / 10);
    
    int count = [self.arrLocations count];
    if (count > MAX_LOCATIONS) count = MAX_LOCATIONS; 
    for (int i = 0; i < count; i++) {
        UILabel *locLabel = [self.locLabels objectAtIndex:i];
        UIImageView *radarPoint = [self.radarPoints objectAtIndex:i];
        ArrLocation *arrLocation = [self.arrLocations objectAtIndex:i];
        
        float diffBearing = [arrLocation bearing] - self.locationManager.heading.trueHeading;
        float distance = [arrLocation distance];
        
        //radarpoints
        float rDF = 0;
        float diffBearingRad = [ArrGeoTools degToRad:(diffBearing - 90)];
        if(distance > 1000) rDF = 38;
        else rDF = 38 * (distance / 1000);
        [radarPoint setTransform:CGAffineTransformMakeTranslation(cos(diffBearingRad) * (rDF), sin(diffBearingRad) * (rDF))];
        
        //check if lable is visible
        float labelFOV = FOV_H + (LOCATION_LABEL_WIDTH / 2) / POINTS_PER_DEG_H;
        if(diffBearing > -labelFOV && diffBearing < labelFOV) {
            diffBearing += FOV_H;
            [locLabel setHidden:NO];
            
            //set label text
            [locLabel setText:[NSString stringWithFormat:@"%@ (%i m)",
                                        [[self.arrLocations objectAtIndex:i] title],
                                        (int) distance
                                        ]];
            
            //scaling + translation
            float scale = 1;
            if(distance <= SCALE_MIN_DISTANCE)
                scale = 1;
            else if(distance >= SCALE_MAX_DISTANCE)
                scale = SCALE_MINIMUM;
            else scale = 1 - ((distance - SCALE_MIN_DISTANCE) * SCALE_FACTOR);
            
            CGAffineTransform aScale = CGAffineTransformMakeScale(scale, scale);
            CGAffineTransform aTranslation = CGAffineTransformMakeTranslation((diffBearing * POINTS_PER_DEG_H) * (1 / scale), 
                                                                              yTransform * (1 / scale));
            CGAffineTransform aTransform = CGAffineTransformConcat(aTranslation, aScale);
            [locLabel setTransform:aTransform];
        } else {
            [locLabel setHidden:YES];
        }
    }
}

//creates a UILabel. Position of the first label is middle of screen. Position
//of following labels is above/under the first label.
- (void)createLocationLabel:(ArrLocation *)arrLocation {    
    int count = [self.locLabels count];
    int xPos = - (LOCATION_LABEL_WIDTH / 2); //position the lable center on the edge of the screen
    int yPos = 160 - (LOCATION_LABEL_HEIGTH / 2);
    if (count % 2)
        yPos += ((LOCATION_LABEL_HEIGTH + LOCATION_LABEL_GAP) * ((count + 1) / 2));
    else
        yPos -= ((LOCATION_LABEL_HEIGTH + LOCATION_LABEL_GAP) * ((count + 1) / 2));
    
    //create label
    UILabel *locLabel = [[UILabel alloc] initWithFrame:CGRectMake(
                                                                  xPos, 
                                                                  yPos, 
                                                                  LOCATION_LABEL_WIDTH, 
                                                                  LOCATION_LABEL_HEIGTH
                                                                  )];
    //customize label
    [locLabel setText:arrLocation.title];
    [locLabel setBackgroundColor:[UIColor redColor]];
    [locLabel setTextColor:[UIColor blackColor]];
    [locLabel setFont:[UIFont boldSystemFontOfSize:14]];
    [locLabel setTextAlignment:UITextAlignmentCenter];
    [locLabel.layer setCornerRadius:4];
    [locLabel.layer setBorderWidth:2];
    [locLabel.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [locLabel setHidden:YES];
    [self.view addSubview:locLabel];
    [self.locLabels addObject:locLabel];
    [locLabel release];
    
    //radar
    UIImageView *radarPoint = [[UIImageView alloc] initWithFrame:CGRectMake(42, 42, 6, 6)];
    [radarPoint setImage:[UIImage imageNamed:@"ArrRadarpoint"]];
    [self.view addSubview:radarPoint];
    [self.radarPoints addObject:radarPoint];
    [radarPoint release];
}

+ (Boolean)isSupported {
    CMMotionManager *tempMM = [[CMMotionManager alloc] init];
    bool isDeviceMotionAvaiable = tempMM.deviceMotionAvailable;
    [tempMM release];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
        && [CLLocationManager locationServicesEnabled]
        && isDeviceMotionAvaiable)
        return true;
    
    return false;
}

#pragma mark - Other

- (void)sortArrLocations {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    arrLocations = [[arrLocations sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
    [sortDescriptor release];
}

@end
