//******************************************************************************
//
// Copyright (c) 2016 Intel Corporation. All rights reserved.
// Copyright (c) 2016 Microsoft Corporation. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************

#import "CoreLocationViewController.h"
#include <cmath>

@implementation CoreLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect bounds = [[UIScreen mainScreen] bounds];

    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height)];
    scrollView.backgroundColor = [UIColor whiteColor];
    scrollView.contentSize = CGSizeMake(450, 1200);
    scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

    buttonLength = 72;
    locHeight = 80;
    headingHeight = 280;

    // Create the location manager if this object does not
    // already have one.
    locationManager = [[CLLocationManager alloc] init];
    [locationManager requestWhenInUseAuthorization];

    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    // Set a movement threshold for new events.
    locationManager.distanceFilter = 500; // meters

    [self setupLocation];

    if ([CLLocationManager headingAvailable]) {
        [self setupHeading];
    } else {
        headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, headingHeight, 300, 50)];
        [headingLabel setBackgroundColor:nil];
        [headingLabel setText:@"Heading Not Available!"];
        [headingLabel setTextAlignment:NSTextAlignmentLeft];
        [scrollView addSubview:headingLabel];
    }

    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:scrollView];
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations {
    NSLog(@"Hit didUpdateLocations");
    CLLocation* location = [locations lastObject];

    dispatch_async(dispatch_get_main_queue(), ^{
        [locVal setText:[NSString stringWithFormat:@"Longitude: %.3f        Latitude: %.3f        ",
                                                   location.coordinate.latitude,
                                                   location.coordinate.longitude]];
    });
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error {
    NSLog(@"Error: %@", error.description);
}

// Methods for Location
- (void)setupLocation {
    locLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, locHeight - 5, 150, 50)];
    [locLabel setBackgroundColor:[UIColor whiteColor]];
    [locLabel setText:@"Location"];
    [locLabel setTextAlignment:NSTextAlignmentLeft];
    [scrollView addSubview:locLabel];

    locStartButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [locStartButton setTitle:@"Start" forState:UIControlStateNormal];
    locStartButton.frame = CGRectMake(100, locHeight, buttonLength, 40);
    [locStartButton addTarget:self action:@selector(locStartButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:locStartButton];

    locStopButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [locStopButton setTitle:@"Stop" forState:UIControlStateNormal];
    locStopButton.frame = CGRectMake(180, locHeight, buttonLength, 40);
    locStopButton.enabled = NO;
    [locStopButton addTarget:self action:@selector(locStopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:locStopButton];

    locUpdateButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [locUpdateButton setTitle:@"Poll Values" forState:UIControlStateNormal];
    locUpdateButton.frame = CGRectMake(270, locHeight, buttonLength * 1.3f, 40);
    [locUpdateButton addTarget:self action:@selector(locUpdateButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    locUpdateButton.enabled = YES;
    [scrollView addSubview:locUpdateButton];

    locVal = [[UILabel alloc] initWithFrame:CGRectMake(0, locHeight + 50, 350, 40)];
    [locVal setBackgroundColor:[UIColor whiteColor]];
    [locVal setText:@"Longitude: 0.000        Latitude: 0.000        "];
    [locVal setTextAlignment:NSTextAlignmentRight];
    [scrollView addSubview:locVal];
}

- (void)locStopUpdates {
    [locationManager stopUpdatingLocation];
}

- (void)locStartUpdates {
    NSLog(@"Location services enabled? %d", [CLLocationManager locationServicesEnabled]);
    [locationManager startUpdatingLocation];
}

- (void)locStopButtonPressed:(UIButton*)button {
    locStartButton.enabled = YES;
    locStopButton.enabled = NO;

    [self locStopUpdates];
}

- (void)locUpdateButtonPressed:(UIButton*)button {
    NSLog(@"Location services enabled? %d", [CLLocationManager locationServicesEnabled]);
    [locationManager requestLocation];
}

- (void)locStartButtonPressed:(UIButton*)button {
    locStartButton.enabled = NO;
    locStopButton.enabled = YES;

    [self locStartUpdates];
}

// Methods for Heading
- (void)setupHeading {
    headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, headingHeight - 5, 150, 50)];
    [headingLabel setBackgroundColor:[UIColor whiteColor]];
    [headingLabel setText:@"Heading"];
    [headingLabel setTextAlignment:NSTextAlignmentLeft];
    [scrollView addSubview:headingLabel];

    headingStartButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [headingStartButton setTitle:@"Start" forState:UIControlStateNormal];
    headingStartButton.frame = CGRectMake(100, headingHeight, buttonLength, 40);
    [headingStartButton addTarget:self action:@selector(headingStartButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:headingStartButton];

    headingStopButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [headingStopButton setTitle:@"Stop" forState:UIControlStateNormal];
    headingStopButton.frame = CGRectMake(180, headingHeight, buttonLength, 40);
    headingStopButton.enabled = NO;
    [headingStopButton addTarget:self action:@selector(headingStopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:headingStopButton];

    headingVal = [[UILabel alloc] initWithFrame:CGRectMake(0, headingHeight + 50, 350, 40)];
    [headingVal setBackgroundColor:[UIColor whiteColor]];
    [headingVal setText:@"Magnetic Heading: 0.000        True Heading: 0.000        "];
    [headingVal setTextAlignment:NSTextAlignmentRight];
    [scrollView addSubview:headingVal];
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager*)manager didUpdateHeading:(CLHeading*)heading {
    dispatch_async(dispatch_get_main_queue(), ^{
        [headingVal setText:[NSString stringWithFormat:@"Magnetic Heading: %.3f        True Heading: %.3f        ",
                                                       heading.magneticHeading,
                                                       heading.trueHeading]];
    });
}

- (void)headingStopUpdates {
    NSLog(@"Location services enabled? %d", [CLLocationManager locationServicesEnabled]);
    [locationManager stopUpdatingHeading];
}

- (void)headingStartUpdates {
    NSLog(@"Location services enabled? %d", [CLLocationManager locationServicesEnabled]);
    [locationManager startUpdatingHeading];
}

- (void)headingStopButtonPressed:(UIButton*)button {
    headingStartButton.enabled = YES;
    headingStopButton.enabled = NO;

    [self headingStopUpdates];
}

- (void)headingStartButtonPressed:(UIButton*)button {
    headingStartButton.enabled = NO;
    headingStopButton.enabled = YES;

    [self headingStartUpdates];
}

@end
