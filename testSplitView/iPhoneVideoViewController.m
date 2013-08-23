//
//  iPhoneVideoViewController.m
//  Innoserv
//
//  Created by philippe nougaillon on 23/08/13.
//  Copyright (c) 2013 philippe nougaillon. All rights reserved.
//

#import "iPhoneVideoViewController.h"
#import "SrtParser.h"
#import <MediaPlayer/MediaPlayer.h>

@interface iPhoneVideoViewController () {

    NSString *langueCourante;
    UIView *myView;

}

@property (nonatomic, retain) SrtParser *srtParser;
@property (nonatomic, retain) UILabel *subtitleLabel;
@property (nonatomic, retain) NSTimer *subtitleTimer;
@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;

-(void)prepareView;
@end

@implementation iPhoneVideoViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self prepareView];
}

-(void)prepareView {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    // Language ?
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *langues = [defaults objectForKey:@"AppleLanguages"];
    langueCourante = [langues objectAtIndex:0];
    
    //NSLog(@"langue: %@",langueCourante);
    
    // Prepare video subtitles
    if ([langueCourante isEqualToString:@"fr"]) {
        // Parse subtitles
        NSString *srtPath = [[NSBundle mainBundle] pathForResource:self.detailItem.subTitles ofType:@"txt"];
        self.srtParser = [[SrtParser alloc] init];
        [self.srtParser parseSrtFileAtPath:srtPath];
    }
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                         pathForResource:self.detailItem.videofile ofType:@"mp4"]];
    
    // A place for video player and subtitles
    myView =[[UIView alloc] initWithFrame:self.view.frame];
    
    // Movieplayer setup
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
    //self.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    self.moviePlayer.view.frame = myView.bounds;
    
    [myView addSubview:self.moviePlayer.view];
    [self.moviePlayer setFullscreen:NO animated:NO];
    
    if ([langueCourante isEqualToString:@"fr"] && self.detailItem.subTitles) {
        
        // A place for subtitles
        // Depending of the current orientation
        UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
        if (UIDeviceOrientationIsLandscape(deviceOrientation)) {
            self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 240, 480, 40)];
            self.subtitleLabel.Font = [UIFont fontWithName:@"Open Sans" size:14];
        } else {
            self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 350, 320, 60)];
            self.subtitleLabel.Font = [UIFont fontWithName:@"Open Sans" size:12];
        }
        // A place for subtitles
        self.subtitleLabel.numberOfLines = 2;
        self.subtitleLabel.backgroundColor = [UIColor whiteColor];
        self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
        self.subtitleLabel.textColor = [UIColor blackColor];
        [myView addSubview:self.subtitleLabel];
        
        // Register for Timer
        [self.subtitleTimer invalidate];
        self.subtitleTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateSubtitles) userInfo:self repeats:YES];
    }
    
    // Affiche la vue video+subtitles
    [self.view addSubview:myView];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayer
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:self.moviePlayer];
    
    // Register this class as an observer instead
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieFinishedCallback:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.moviePlayer];

    
}

- (void)movieFinishedCallback:(NSNotification*)aNotification
{
    MPMoviePlayerController *myMoviePlayer = [aNotification object];
    
    // Remove this class from the observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:myMoviePlayer];
    
    [self.moviePlayer stop];
    
    [myView removeFromSuperview];
    myView =nil;
    
    [self.subtitleTimer invalidate];
    self.subtitleTimer = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Subtitles

-(void)updateSubtitles
{
    NSString *subTitleText;
    NSDate *initialDate = [self.srtParser initialTime];
    NSDate *currentTime = [initialDate dateByAddingTimeInterval:self.moviePlayer.currentPlaybackTime];
    
    subTitleText = [self.srtParser textForTime:currentTime];
    if (![subTitleText isEqualToString:self.subtitleLabel.text]) {
        self.subtitleLabel.text = subTitleText;
        //NSLog(@"text: %@", subTitleText);
    }
}

// Orientation changed notification
- (void)orientationChanged:(NSNotification *)notification
{
        NSLog(@"Orientation changed");
    
        [self.moviePlayer stop];

        //remove previous view
        [myView removeFromSuperview];
        myView =nil;
    
        // Stop subtitles
        [self.subtitleTimer invalidate];
        self.subtitleTimer = nil;

        // call a new view with appropriate format
        [self prepareView];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
