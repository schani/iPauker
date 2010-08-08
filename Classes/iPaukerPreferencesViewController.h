#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class iPaukerViewController;

@interface iPaukerPreferencesViewController : UIViewController
{
    IBOutlet UITextField *emailTextField;
    IBOutlet UITextField *passwordTextField;
    IBOutlet UITextField *lessonTextField;

    iPaukerViewController *mainViewController;
}

- (IBAction) done: (id) sender;

- (void) setIPaukerViewController: (iPaukerViewController*) controller;

@end
