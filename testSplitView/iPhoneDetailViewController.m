//
//  iPhoneDetailViewController.m
//  Innoserv
//
//  Created by philippe nougaillon on 09/04/13.
//  Copyright (c) 2013 philippe nougaillon. All rights reserved.
//

#import "iPhoneDetailViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SrtParser.h"

@interface iPhoneDetailViewController ()
{
    NSString *langueCourante;
    UIWebView *videoView;
    UIView *myView;
    
    __weak IBOutlet UIBarButtonItem *openWebPageToolBarButton;
    __weak IBOutlet UILabel *projectSubTiltle;
    __weak IBOutlet UITextView *projectInformation;
    __weak IBOutlet UIImageView *projectImage;
}

@property (nonatomic, retain) SrtParser *srtParser;
@property (nonatomic, retain) UILabel *subtitleLabel;
@property (nonatomic, retain) NSTimer *subtitleTimer;
@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;


@end

@implementation iPhoneDetailViewController

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
    
    //localize buttons
    openWebPageToolBarButton.title = NSLocalizedString(@"Website", @"");
    
    //set fonts
    [projectSubTiltle setFont:[UIFont fontWithName:@"Open Sans" size:18]];
    [projectInformation setFont:[UIFont fontWithName:@"Open Sans" size:14]];
    
	// Do any additional setup after loading the view.
    if (self.detailItem) {
        
        // Language ?
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *langues = [defaults objectForKey:@"AppleLanguages"];
        langueCourante = [langues objectAtIndex:0];
        
        //NSLog(@"langue: %@",langueCourante);
        
        // Load items for appropriate language
        if ([langueCourante isEqualToString:@"fr"]) {
        }
        
        // Prepare video subtitles
        if ([langueCourante isEqualToString:@"fr"]) {
            // Parse subtitles
            NSString *srtPath = [[NSBundle mainBundle] pathForResource:self.detailItem.subTitles ofType:@"txt"];
            self.srtParser = [[SrtParser alloc] init];
            [self.srtParser parseSrtFileAtPath:srtPath];
        }
        
        projectSubTiltle.text = self.detailItem.description;
        projectInformation.text = self.detailItem.information;

        NSString *imageFileName = [self.detailItem.image stringByAppendingString:@"-big.png"];
        projectImage.image = [UIImage imageNamed:imageFileName];
        
        // if website > show info button
        if ([self.detailItem.website isEqualToString:@""])
            openWebPageToolBarButton.enabled = NO;
        else
            openWebPageToolBarButton.enabled = YES;

    }
}

- (IBAction)openWebPagePressed:(id)sender {
    
    if (self.detailItem) {
        
        NSString *webPageLink = self.detailItem.website;
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:webPageLink]];
    }
}
- (IBAction)playVideoButtonPressed:(id)sender {
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                         pathForResource:self.detailItem.videofile ofType:@"mp4"]];
    
    // A place for video player and subtitles
    //myView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
    myView = [[UIView alloc] initWithFrame:projectImage.frame];
    
    // Movieplayer setup
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
    //self.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    self.moviePlayer.view.frame = myView.bounds;
    
    [myView addSubview:self.moviePlayer.view];
    [self.moviePlayer setFullscreen:NO animated:NO];
    
    if ([langueCourante isEqualToString:@"fr"] && self.detailItem.subTitles) {
        // A place for subtitles
        self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 150, 200, 30)];
        self.subtitleLabel.backgroundColor = [UIColor whiteColor];
        self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
        self.subtitleLabel.Font = [UIFont fontWithName:@"Open Sans" size:10];
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
    

    // self.openWebPageToolBarButton.enabled= NO;
    //self.navigationController.navigationBarHidden = YES;
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

// This will get called too before the view appears
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"openVideo"]) {
        
        // Get destination view
        iPhoneDetailViewController *vc = [segue destinationViewController];
        
        // Pass the information to your destination view
        vc.detailItem = self.detailItem;
        vc.navigationItem.title = self.detailItem.title;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTitle:nil];
    [super viewDidUnload];
}
@end
