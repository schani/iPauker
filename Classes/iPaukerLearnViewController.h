//
//  iPaukerLearnViewController.h
//  iPauker
//
//  Created by Mark Probst on 8/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardProcessing.h"
#import "Card.h"

@class CardProcessing;

@interface iPaukerLearnViewController : UIViewController {
    IBOutlet UITextView *questionText;
    IBOutlet UITextView *answerText;
    IBOutlet UIBarButtonItem *showButton;
    IBOutlet UIBarButtonItem *correctButton;
    IBOutlet UIBarButtonItem *incorrectButton;
    
    BOOL isLoaded;

    CardProcessing *processing; // nil if we are to restore from saved state
    Card *card;
    CardSet *cardSet;
}

- (CardSet*) cardSet;

- (IBAction)cancel:(id)sender;
- (IBAction)show:(id)sender;
- (IBAction)correct:(id)sender;
- (IBAction)incorrect:(id)sender;

+ (BOOL) hasSavedState;
- (void) restoreFromSavedStateWithCardSet: (CardSet*) cs;

- (BOOL) learnNewFromCardSet: (CardSet*) cardSet;
- (BOOL) repeatExpiredFromCardSet: (CardSet*) cardSet;

- (void) askCard: (Card*) c;
- (void) showCard: (Card*) c;
- (void) finishLearning;

@end
