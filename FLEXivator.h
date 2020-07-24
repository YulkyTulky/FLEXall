#import <UIKit/UIKit.h>
#import <libactivator/libactivator.h>

//--Defines--//
#define kFLEXivatorWindowLevel 2050
#define kFLEXivatorLongPressType 1337
#define kFLEXivatorBlacklistPath @"/var/mobile/Library/Preferences/com.yulkytulky.FLEXivator.blacklist.plist"
#define kFLEXivatorObjectGraphSectionTitle @"Object Graph"
#define kFLEXivatorDisableIdleTimerReason @"FLEXivatorDisableIdle"

//--Function Declarations--//
static void openFLEX();
static id (* GetFLXManager)();
static SEL (* GetFLXRevealSEL)();
static Class (* GetFLXWindowClass)();

//--Enums--//
typedef NS_ENUM(NSUInteger, FLEXObjectExplorerSection) { 
    FLEXObjectExplorerSectionDescription,
    FLEXObjectExplorerSectionCustom,
    FLEXObjectExplorerSectionProperties,
    FLEXObjectExplorerSectionIvars,
    FLEXObjectExplorerSectionMethods,
    FLEXObjectExplorerSectionClassMethods,
    FLEXObjectExplorerSectionSuperclasses,
    FLEXObjectExplorerSectionReferencingInstances
};

//--Interface Declarations--//
@interface SBApplication
@property NSString *bundleIdentifier;
@end

@interface SpringBoard: UIApplication
- (SBApplication *)_accessibilityFrontMostApplication;
- (BOOL)isLocked;
@end

@interface SBBacklightController: NSObject
+ (id)sharedInstance;
- (void)resetLockScreenIdleTimer; 
@end

@interface SBDashBoardIdleTimerProvider: NSObject 
- (void)addDisabledIdleTimerAssertionReason:(id)arg1; 
- (void)removeDisabledIdleTimerAssertionReason:(id)arg1; 
@end

@interface SBDashBoardViewController: UIViewController { 
	SBDashBoardIdleTimerProvider *_idleTimerProvider; 
}
@end

@interface SBDashBoardIdleTimerController: NSObject { 
	SBDashBoardIdleTimerProvider *_dashBoardIdleTimerProvider; 
}
@end

@interface CSCoverSheetViewController: UIViewController 
- (id)idleTimerController; 
@end

@interface SBCoverSheetPresentationManager: NSObject 
+ (id)sharedInstance; 
- (id)dashBoardViewController; 
- (id)coverSheetViewController; 
@end

@interface SBMainDisplaySceneLayoutStatusBarView: UIView 
- (void)_statusBarTapped:(id)arg1 type:(NSInteger)arg2; 
@end

@interface FLEXExplorerViewController: UIViewController
- (void)resignKeyAndDismissViewControllerAnimated:(BOOL)arg1 completion:(id)arg2; 
@end

@interface FLEXManager: NSObject
@property (nonatomic) FLEXExplorerViewController *explorerViewController;
+ (FLEXManager *)sharedManager;
@end

@interface FLEXWindow: UIWindow
@end

@interface FLEXTableViewSection: NSObject 
@property (nonatomic, readonly, nullable) NSString *title;
@end

@interface FLEXSingleRowSection: FLEXTableViewSection 
@end

@interface FLEXObjectExplorerViewController: UITableViewController
@property (nonatomic, readonly) FLEXTableViewSection *customSection; 
@end

@interface NSObject (PrivateFLEXivator)
- (id)safeValueForKey:(id)arg1;
@end

@interface UIWindow (PrivateFLEXivator)
@property (nonatomic, strong) UILongPressGestureRecognizer *FLEXivatorLongPress;
@end