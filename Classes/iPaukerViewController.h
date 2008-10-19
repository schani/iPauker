#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "CardSet.h"
#import "iPaukerLearnViewController.h"

@interface iPaukerViewController : UIViewController {
    IBOutlet UILabel *expiredLabel;
    IBOutlet UILabel *learnedLabel;
    IBOutlet UILabel *totalLabel;
    IBOutlet UILabel *newLabel;
    CardSet *cardSet;
    iPaukerLearnViewController *learnViewController;
}

- (IBAction)settings:(id)sender;
- (IBAction)update:(id)sender;

- (IBAction)learnNew:(id)sender;
- (IBAction)repeatExpired:(id)sender;

- (void) updateStats;

- (void) setCardSet: (CardSet*) cs;

@end
