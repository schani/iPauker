#import "PreferencesController.h"

#import "iPaukerPreferencesViewController.h"
#import "iPaukerViewController.h"

@implementation iPaukerPreferencesViewController

- (void) viewWillAppear: (BOOL) animated
{
    PreferencesController *pref = [PreferencesController sharedPreferencesController];

    [super viewWillAppear: animated];

    [emailTextField setText: [pref userName]];
    [passwordTextField setText: [pref password]];
    [lessonTextField setText: [pref mainLessonName]];
}

- (IBAction) done: (id) sender
{
    PreferencesController *pref = [PreferencesController sharedPreferencesController];

    [pref setUserName: [emailTextField text]];
    [pref setPassword: [passwordTextField text]];
    [pref setMainLessonName: [lessonTextField text]];

    if (mainViewController)
	[mainViewController loadLesson];

    [self dismissModalViewControllerAnimated: TRUE];
}

- (void) setIPaukerViewController: (iPaukerViewController*) controller
{
    mainViewController = controller;
}

@end
