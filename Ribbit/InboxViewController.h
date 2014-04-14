//
//  InboxViewController.h
//  Ribbit
//
//  Created by Joaquin Cubero on 03/11/13.
//  Copyright (c) 2013 Joaquin Cubero. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <MediaPlayer/MediaPlayer.h>

@interface InboxViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) NSArray *sentMessages;
@property (nonatomic, strong) NSArray *recivedMessages;
@property (nonatomic, strong) NSMutableDictionary *preloadObjects;
@property BOOL sentComplete;
@property BOOL recivedComplete;
@property (nonatomic, strong) PFObject *selectedMessage;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

- (IBAction)logOut:(id)sender;


@property (strong, nonatomic) IBOutlet UITableView *inboxTable;
@property (strong, nonatomic) IBOutlet UIView *imageView;
@property (strong, nonatomic)  UIImageView *messageImage;
@property (nonatomic, strong) MPMoviePlayerViewController *movieViewPlayer;
@property (nonatomic,strong) NSString* videoTemporaryPath;
@property (strong, nonatomic)  UILabel *lblCounter;

@end
