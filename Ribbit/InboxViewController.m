//
//  InboxViewController.m
//  Ribbit
//
//  Created by Joaquin Cubero on 03/11/13.
//  Copyright (c) 2013 Joaquin Cubero. All rights reserved.
//

#import "InboxViewController.h"
#import "MSCellAccessory.h"
#import "GlobalTimer.h"
#import <QuartzCore/QuartzCore.h>

@interface InboxViewController ()

@end

static UITableViewCell* currentCell;
static NSString* currentCellText;
static BOOL isViewing=NO;
static NSTimer* refreshTimer;


@implementation InboxViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sentComplete = NO;
    self.recivedComplete = NO;
    self.preloadObjects = [[NSMutableDictionary alloc] init];
    self.lblCounter = [[UILabel alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 40 , 20, 30, 30)];
    self.lblCounter.textColor = [UIColor whiteColor];
    self.lblCounter.backgroundColor = [UIColor grayColor];
    self.lblCounter.textAlignment =NSTextAlignmentCenter;
    self.lblCounter.layer.cornerRadius = 10.0;
    self.lblCounter.layer.masksToBounds = YES;
    self.lblCounter.font = [UIFont boldSystemFontOfSize:15.0];
    
    //Creates the temporary repository file path for the videos
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    self.videoTemporaryPath = [documentsDirectory stringByAppendingPathComponent:@"mymvc.mov"];
    
    PFUser *currentUser = [PFUser currentUser];
    
    self.inboxTable.delegate = self;
    if (currentUser) {
        NSLog(@"Current user: %@", [currentUser username]);
        refreshTimer=  [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(retriveMessages) userInfo:nil repeats:YES];
        
        [self retriveMessages];
    } else {
        [self performSegueWithIdentifier:@"showLogin" sender:self];
    }
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    
    [self.refreshControl addTarget:self action:@selector(retriveMessages) forControlEvents:UIControlEventValueChanged];
    
    UILongPressGestureRecognizer* longPressGestureRec =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    longPressGestureRec.minimumPressDuration = .5;
    [self.view addGestureRecognizer:longPressGestureRec];
    
    [self hideMessageContent];
}

-(void) longPressGesture:(UIGestureRecognizer*)gesture{
    NSLog(@"Long Press");
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        
        CGPoint p = [gesture locationInView:self.inboxTable];
        
        NSIndexPath *indexPath = [self.inboxTable indexPathForRowAtPoint:p];
        if (indexPath == nil) {
            NSLog(@"long press on table view but not on a row");
        } else {
            UITableViewCell *cell = [self.inboxTable cellForRowAtIndexPath:indexPath];
            if (cell.isHighlighted) {
                
                if (([cell isEqual:currentCell]) && (isViewing)){
                    
                    self.selectedMessage = [self.messages objectAtIndex:indexPath.row];
                    
                    [self showMessageContent];
                }
                else if ((![cell isEqual:currentCell]) && (!isViewing)){
                    if (cell.textLabel.tag==0){
                        currentCell = cell;
                        currentCellText = cell.textLabel.text;
                        
                        self.selectedMessage = [self.messages objectAtIndex:indexPath.row];
                        
                        NSLog(@"ShowContent");
                        [self showMessageContent];

                        
                        
                        NSMutableArray *viewedIds = [NSMutableArray arrayWithArray:[self.selectedMessage objectForKey:@"viewedIds"]];
                        NSLog(@"viewedIds: %@", viewedIds);
                        
                        
                        [viewedIds addObject:[[PFUser currentUser] objectId]];
                        [self.selectedMessage setObject:viewedIds forKey:@"viewedIds"];
                        [self.selectedMessage saveInBackground];
                        
                        GlobalTimer* ribbitTimer = [GlobalTimer ribbitTimer];
                        
                        [ribbitTimer startTimer];
                    }
                }
            }
        }
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        [self hideMessageContent];
    }
}

-(void)showMessageContent
{
    self.inboxTable.hidden = YES;
    self.imageView.hidden = NO;
    
    
    
        NSString *fileType = [self.selectedMessage objectForKey:@"fileType"];
        PFFile *messageFile = [self.selectedMessage objectForKey:@"file"];
        NSURL *messageFileUrl = [NSURL URLWithString:messageFile.url];
        NSData *msgData;
        if ([self.preloadObjects objectForKey:[self.selectedMessage objectId]]) {
            msgData =[self.preloadObjects objectForKey:[self.selectedMessage objectId]];
        }
        else
        {
            msgData = [NSData dataWithContentsOfURL:messageFileUrl];
        }

    
    
        if ([fileType isEqualToString:@"image"]) {
            if (!isViewing){
                self.messageImage = [[UIImageView alloc]init];
                self.messageImage.image = [UIImage imageWithData:msgData];
                self.messageImage.frame = self.view.frame;
                [self.messageImage addSubview:self.lblCounter];
                [self.imageView addSubview:self.messageImage];
                

            }
            else
            {
                self.messageImage.hidden = NO;
            }
            
            
        }
        else{
            
            if (!isViewing){
                [msgData writeToFile:self.videoTemporaryPath atomically:YES];
                
                NSURL *moveUrl = [NSURL fileURLWithPath:self.videoTemporaryPath];
                
                //play the file
                self.movieViewPlayer = [[MPMoviePlayerViewController alloc]  initWithContentURL:moveUrl];
                self.movieViewPlayer.moviePlayer.controlStyle = MPMovieControlStyleNone;
                [self.movieViewPlayer.view setFrame:self.view.frame];
                self.movieViewPlayer.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
                [self.movieViewPlayer.moviePlayer setRepeatMode:MPMovieRepeatModeOne];
                [self.movieViewPlayer.moviePlayer play];
                [self.movieViewPlayer.view addSubview:self.lblCounter];
                [self.imageView addSubview:self.movieViewPlayer.view];
            }
            else
            {
                self.movieViewPlayer.view.hidden = NO;
                [self.movieViewPlayer.moviePlayer play];
            }
            
           
        }
        isViewing = YES;
    
        [self.navigationController setNavigationBarHidden:YES];
        self.tabBarController.tabBar.hidden = YES;
}



-(void)hideMessageContent
{
    self.inboxTable.hidden = NO;
    self.imageView.hidden = YES;
    [self.navigationController setNavigationBarHidden:NO];
    self.tabBarController.tabBar.hidden = NO;
    
    NSString *fileType = [self.selectedMessage objectForKey:@"fileType"];
    
    if ([fileType isEqualToString:@"image"]) {
        //[self.messageImage removeFromSuperview];
        self.messageImage.hidden = YES;
    }
    else{
        //[self.movieViewPlayer.view removeFromSuperview];
        [self.movieViewPlayer.moviePlayer pause];
        self.movieViewPlayer.view.hidden = YES;
    }
    
   // [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

-(void)removeTemporaryVideoFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
   
    NSError *error;
    BOOL success =[fileManager removeItemAtPath:self.videoTemporaryPath error:&error];
    if (!success) {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    
    NSNumber* localTimerValue =[GlobalTimer ribbitTimer].timerValue;
    currentCell.textLabel.text  = [NSString stringWithFormat:@"%@ - %@",currentCellText, localTimerValue];
    self.lblCounter.text = [NSString stringWithFormat:@"%@", localTimerValue];
    
    if ([localTimerValue integerValue]  <= 0){
        currentCell.textLabel.text=[NSString stringWithFormat:@"%@",currentCellText];
        self.lblCounter.text = @"";
        if ([[self.selectedMessage objectForKey:@"fileType"] isEqualToString:@"image"])
        {
            [self.messageImage removeFromSuperview];
            currentCell.imageView.image = [UIImage imageNamed:@"read.png"];
        }
        else
        {
            [self.movieViewPlayer.view removeFromSuperview];
            [self removeTemporaryVideoFile];
            currentCell.imageView.image = [UIImage imageNamed:@"readfilm.png"];
        }
        [self hideMessageContent];
        currentCell.textLabel.tag = 1;
        isViewing = NO;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[GlobalTimer ribbitTimer] removeObserver:self forKeyPath:@"timerValue" ];
   }

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setHidden:NO];
    
    [[GlobalTimer ribbitTimer] addObserver:self forKeyPath:@"timerValue" options:NSKeyValueObservingOptionNew context:NULL];
    
    NSNumber* localTimerValue =[GlobalTimer ribbitTimer].timerValue;
    if ((currentCell)&&(isViewing)&&([localTimerValue integerValue]  <= 0))
    {
        currentCell.textLabel.text=[NSString stringWithFormat:@"%@",currentCellText];
       
        
        if ([[self.selectedMessage objectForKey:@"fileType"] isEqualToString:@"image"])
            {
                currentCell.imageView.image = [UIImage imageNamed:@"read.png"];
            }
            else
            {
                 [self removeTemporaryVideoFile];
                 currentCell.imageView.image = [UIImage imageNamed:@"readfilm.png"];
            }
            
        currentCell.textLabel.tag = 1;
        isViewing = NO;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    PFObject *message = [self.messages objectAtIndex:indexPath.row];
    
    NSDate *created = [message createdAt];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"EEE, MMM d, h:mm a"];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", [dateFormat stringFromDate:created]];
    
    NSString* currentUserId = [[PFUser currentUser] objectId];
    
    NSMutableArray *viewedIds = [NSMutableArray arrayWithArray:[message objectForKey:@"viewedIds"]];
    
    BOOL wasRead;
    
    
   for (NSString *viewedId in viewedIds) {
       if ([viewedId isEqualToString:currentUserId]){
                wasRead=YES;
        }
    }
    
    NSString *fileType = [message objectForKey:@"fileType"];
    
    if ([fileType isEqualToString:@"image"]) {
        if (wasRead) {
            cell.imageView.image = [UIImage imageNamed:@"read.png"];
            cell.textLabel.tag = 1;
        }
        else
        {
            cell.imageView.image = [UIImage imageNamed:@"unread.png"];
            cell.textLabel.tag = 0;
        }
    }
    else{
        if (wasRead) {
            cell.imageView.image = [UIImage imageNamed:@"readfilm.png"];
            cell.textLabel.tag = 1;
        }
        else
        {
            cell.imageView.image = [UIImage imageNamed:@"unreadfilm.png"];
            cell.textLabel.tag = 0;
        }
    }
    
    if ([[message objectForKey:@"senderId"] isEqualToString: currentUserId]){
        cell.imageView.image = [UIImage imageNamed:@"sent.png"];
        cell.textLabel.tag = 1;
    }
    
    if (cell.textLabel.tag == 0) {
    
        if(![self.preloadObjects objectForKey:[message objectId]]){
            
            PFFile *messageFile = [message objectForKey:@"file"];
            NSURL *messageFileUrl = [NSURL URLWithString:messageFile.url];
            
            [self downloadImageWithURL:messageFileUrl completionBlock:^(BOOL succeeded, NSData *data)
             {
                 if (succeeded) {
                     // change the image in the cell
                     [self.preloadObjects setObject:data forKey:[message objectId]];
                 }
             }];
        }
    }
   
    UIColor *color = [UIColor colorWithRed:0.553 green:0.439 blue:0.718 alpha:1.0];
    cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR color:color];
  
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
   //UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
   // if (([cell isEqual:currentCell]) && (isViewing)){
   //     [self showMessageContent];
   // }
}


- (IBAction)logOut:(id)sender {
    
    [PFUser logOut];
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showLogin"]) {
        [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
    } 
}

#pragma mark - Helper methods

- (void)retriveMessages
{
    if (!isViewing){
        PFQuery *mySentMessages = [PFQuery queryWithClassName:@"Messages"];
        [mySentMessages whereKey:@"senderId" equalTo:[[PFUser currentUser] objectId]];
        [mySentMessages orderByDescending:@"createdAt"];
        [mySentMessages findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                NSLog(@"Error: %@ %@", error, error.userInfo);
            } else {
                // Found messages!
                self.sentComplete= YES;
                self.sentMessages = objects;
                [self mergeSendRecivedMessage];
            }
        }];
        
        
        PFQuery *myMessages = [PFQuery queryWithClassName:@"Messages"];
        [myMessages whereKey:@"recipientsIds" equalTo:[[PFUser currentUser] objectId]];

        [myMessages orderByDescending:@"createdAt"];
        [myMessages findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                NSLog(@"Error: %@ %@", error, error.userInfo);
            } else {
                // Found messages!
                PFObject *message;
                int i;
                for (i=0; i<[objects count]; i++) {
                    message =[objects objectAtIndex:i];
                    [message setValue:@"" forKey:@"senderId"];
                }
                self.recivedComplete = YES;
                self.recivedMessages = objects;
                [self mergeSendRecivedMessage];
            }
        }];
    }
}

-(void)mergeSendRecivedMessage
{
    if ((self.sentComplete) && (self.recivedComplete)){
        NSMutableSet* unionArray = [[NSMutableSet alloc]init];
        NSArray* sortedArray;
        NSArray* allNotifications;

    
        [unionArray unionSet:[NSSet setWithArray:self.sentMessages]];
    
        [unionArray unionSet:[NSSet setWithArray:self.recivedMessages]];
    
        allNotifications = [unionArray allObjects];
        
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO]; //Just write the key for which you
        NSArray * descriptors = [NSArray arrayWithObject:descriptor];
        sortedArray = [allNotifications sortedArrayUsingDescriptors:descriptors];
        
    
        self.messages =sortedArray;
        [self.inboxTable reloadData];
        NSLog(@"Retrived %lu messages", (unsigned long)self.messages.count);
    
    
        if ([self.refreshControl isRefreshing]) {
            [self.refreshControl endRefreshing];
        }
    }

}

- (void)downloadImageWithURL:(NSURL *)url  completionBlock:(void (^)(BOOL succeeded, NSData *data))completionBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ( !error )
                               {
                                   NSData *messageObject = [[NSData alloc] initWithData:data];
                                   
                                   completionBlock(YES,messageObject);
                               } else{
                                   completionBlock(NO,nil);
                               }
                           }];
}



@end
