//
//  LoginViewController.h
//  Ribbit
//
//  Created by Joaquin Cubero on 04/11/13.
//  Copyright (c) 2013 Joaquin Cubero. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController 
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
- (IBAction)logIn:(id)sender;

@end
