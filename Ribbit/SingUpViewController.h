//
//  SingUpViewController.h
//  Ribbit
//
//  Created by Joaquin Cubero on 04/11/13.
//  Copyright (c) 2013 Joaquin Cubero. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SingUpViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
- (IBAction)signUp:(id)sender;
- (IBAction)dismiss:(id)sender;

@end
