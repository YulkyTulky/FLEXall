#import "FLEXivator.h"

////////////////////////////////////////
// Activator Code
static NSString *bundleID = @"com.yulkytulky.flexivatorListener";
static LAActivator *_LASharedActivator;

@interface FLEXivatorListener: NSObject <LAListener>
+ (id)sharedInstance;
@end

@implementation FLEXivatorListener
////////////////////
// Activator Shenanigans
+ (instancetype)sharedInstance {

	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;

}

+ (void)load {

	void *la = dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	if (!la) {
		_LASharedActivator = nil;
	} else {
		_LASharedActivator = [%c(LAActivator) sharedInstance];
	}
	[self sharedInstance];

}

- (instancetype)init {

	if ([super init]) {
		if (_LASharedActivator) {
			if (_LASharedActivator.isRunningInsideSpringBoard) {
				[_LASharedActivator registerListener:self forName:bundleID];
			}
		}
	}
	return self;

}

- (void)dealloc {

	if (_LASharedActivator) {
		if (_LASharedActivator.runningInsideSpringBoard) {
			[_LASharedActivator unregisterListenerWithName:bundleID];
		}
	}

}
/////////////////////////

/////////////////////////
// FLEXivator Listener Code
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {

	SBApplication *frontApp = [(SpringBoard *)[%c(SpringBoard) sharedApplication] _accessibilityFrontMostApplication];
	NSString *bundleID = [frontApp bundleIdentifier];
	if (bundleID) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)[NSString stringWithFormat:@"FLEXivator/%@", bundleID], NULL, nil, YES);
	} else {
		openFLEX();
	}

}
/////////////////////////

/////////////////////////
// Info for Activator
- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
	return @"FLEXivator";
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
	return @"Open FLEXing with Activator!";
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
	return @"FLEX";
}
- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
	return [NSArray arrayWithObjects:@"springboard", @"lockscreen", @"application", nil];
}
- (UIImage *)activator:(LAActivator *)activator requiresSmallIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale {
	return [UIImage imageWithContentsOfFile:@"/Library/MobileSubstrate/DynamicLibraries/FLEXivator.png"];
}
/////////////////////////
@end
////////////////////////////////////////

%hook UIViewController

- (BOOL)_canShowWhileLocked {

	UIViewController *currentViewController = self;
	while (currentViewController != nil) {
		if ([currentViewController isKindOfClass:%c(FLEXExplorerViewController)] || [currentViewController isKindOfClass:%c(FLEXNavigationController)]) {
			return YES;
		}
		if (currentViewController.presentingViewController != nil) {
			currentViewController = currentViewController.presentingViewController;
		} else {
			currentViewController = currentViewController.parentViewController;
		}
	}

	return %orig;

}

%end

%hook FLEXWindow

- (BOOL)_shouldCreateContextAsSecure {

	return YES;

}

- (id)initWithFrame:(CGRect)arg1 {

	self = %orig(arg1);
	if (self != nil) {
		[self setWindowLevel:kFLEXivatorWindowLevel]; 
	}
	return self;

}

%end

%hook FLEXObjectExplorerViewController

- (void)viewDidLoad {

	%orig;
	FLEXManager *manager = GetFLXManager();
	if (self.navigationItem.rightBarButtonItems.count == 0 && [manager.explorerViewController respondsToSelector:@selector(resignKeyAndDismissViewControllerAnimated:completion:)]) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDonePressed:)];
	}

}

- (NSArray<NSNumber *> *)possibleExplorerSections { 

	__block NSArray<NSNumber *> *possibleSections = %orig;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSNumber *referencingInstancesSection = @(FLEXObjectExplorerSectionReferencingInstances);
		NSMutableArray<NSNumber *> *newSections = [possibleSections mutableCopy];
		[newSections removeObject:referencingInstancesSection];
		NSUInteger newIndex = [newSections indexOfObject:@(FLEXObjectExplorerSectionCustom)];
		[newSections insertObject:referencingInstancesSection atIndex:newIndex + 1];
		possibleSections = [newSections copy];
	});
	return possibleSections;

}

- (NSArray<FLEXTableViewSection *> *)makeSections { 

	NSArray<FLEXTableViewSection *> *sections = %orig;
	NSArray<FLEXTableViewSection *> *singleRowSections = [sections filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(FLEXTableViewSection *evaluatedObject, NSDictionary<NSString *,id> *bindings) {
		if ([evaluatedObject isKindOfClass:%c(FLEXSingleRowSection)] && [evaluatedObject.title isEqualToString:kFLEXivatorObjectGraphSectionTitle]) {
			return YES;
		}
		return NO;
	}]];
	NSUInteger customSectionIndex = [sections indexOfObject:self.customSection];
	if (customSectionIndex != NSNotFound && singleRowSections.count > 0) {
		NSMutableArray<FLEXTableViewSection *> *newSections = [sections mutableCopy];
		[newSections removeObjectsInArray:singleRowSections];
		[newSections insertObjects:singleRowSections atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(customSectionIndex + 1, singleRowSections.count)]];
		sections = [newSections copy];
	}
	return sections;

}

%new
- (void)handleDonePressed:(id)arg1 {

	FLEXManager *manager = GetFLXManager();
	if ([manager.explorerViewController respondsToSelector:@selector(resignKeyAndDismissViewControllerAnimated:completion:)]) { 
		[manager.explorerViewController resignKeyAndDismissViewControllerAnimated:YES completion:nil];
	}

}

%end

%group iOS11plusDisableIdleTimer

static SBDashBoardIdleTimerProvider *GetDashBoardIdleTimerProvider() {
	SBCoverSheetPresentationManager *presentationManager = [%c(SBCoverSheetPresentationManager) sharedInstance];
	SBDashBoardIdleTimerProvider *_idleTimerProvider = nil;
	if ([presentationManager respondsToSelector:@selector(dashBoardViewController)]) {
		SBDashBoardViewController *dashBoardViewController = [presentationManager dashBoardViewController];
		_idleTimerProvider = [dashBoardViewController safeValueForKey:@"_idleTimerProvider"];
	} else if ([presentationManager respondsToSelector:@selector(coverSheetViewController)]) {
		SBDashBoardIdleTimerController *dashboardIdleTimerController = [[presentationManager coverSheetViewController] idleTimerController];
		_idleTimerProvider = [dashboardIdleTimerController safeValueForKey:@"_dashBoardIdleTimerProvider"];
	}
	return _idleTimerProvider;
}

%hook FLEXManager

- (void)showExplorer {

	%orig;
	[GetDashBoardIdleTimerProvider() addDisabledIdleTimerAssertionReason:kFLEXivatorDisableIdleTimerReason];

}

- (void)hideExplorer {

	%orig;
	[GetDashBoardIdleTimerProvider() removeDisabledIdleTimerAssertionReason:kFLEXivatorDisableIdleTimerReason];

}

%end

%end

%group preiOS11ResetIdleTimer

%hook FLEXWindow

- (id)hitTest:(CGPoint)arg1 withEvent:(id)arg2 {

	id result = %orig;
	if ([(SpringBoard *)[%c(SpringBoard) sharedApplication] isLocked]) {
		SBBacklightController *backlightController = [%c(SBBacklightController) sharedInstance];
		[backlightController resetLockScreenIdleTimer];
	}
	return result;

}

%end

%end

static id FallbackFLXGetManager() {
	return [%c(FLEXManager) sharedManager];
}

static SEL FallbackFLXRevealSEL() {
	return @selector(showExplorer);
}

static Class FallbackFLXWindowClass() {
	return %c(FLEXWindow);
}

////////////////////////////////////////
// FLEXivator openFLEX Function
static void openFLEX() {

	[GetFLXManager() performSelector:GetFLXRevealSEL()];

}
////////////////////////////////////////

%ctor {

	NSArray *args = [[NSProcessInfo processInfo] arguments];
	if (args != nil && args.count != 0) {
		NSString *execPath = args[0];
		BOOL isSpringBoard = [[execPath lastPathComponent] isEqualToString:@"SpringBoard"];
		BOOL isApplication = [execPath rangeOfString:@"/Application"].location != NSNotFound;
		NSArray *blacklistedProcesses = nil;
		if ([[NSFileManager defaultManager] fileExistsAtPath:kFLEXivatorBlacklistPath]) {
			NSMutableDictionary *blacklistDict = [NSMutableDictionary dictionaryWithContentsOfFile:kFLEXivatorBlacklistPath];
			blacklistedProcesses = [blacklistDict objectForKey:@"blacklist"];
		} else {
			blacklistedProcesses = @[
				@"com.toyopagroup.picaboo" 
			];
		}
		NSString *processBundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
		BOOL isBlacklisted = [blacklistedProcesses containsObject:processBundleIdentifier];
		if (!isBlacklisted) {
			if ((isSpringBoard || isApplication)) {
				void *handle = dlopen("/Library/MobileSubstrate/DynamicLibraries/libFLEX.dylib", RTLD_LAZY);
				if (handle != NULL) {
					GetFLXManager = (id(*)())dlsym(handle, "FLXGetManager") ?: &FallbackFLXGetManager;
					GetFLXRevealSEL = (SEL(*)())dlsym(handle, "FLXRevealSEL") ?: &FallbackFLXRevealSEL;
					GetFLXWindowClass = (Class(*)())dlsym(handle, "FLXWindowClass") ?: &FallbackFLXWindowClass;
					if (%c(SBBacklightController) && [%c(SBBacklightController) instancesRespondToSelector:@selector(resetLockScreenIdleTimer)]) {
						%init(preiOS11ResetIdleTimer, FLEXWindow=GetFLXWindowClass());
					} else if (%c(SBCoverSheetPresentationManager)) {
						%init(iOS11plusDisableIdleTimer, FLEXManager=[GetFLXManager() class]);
					}
					%init(FLEXWindow=GetFLXWindowClass());

					////////////////////////////////////////
					// FLEXivator Notification
					if (!isSpringBoard) {
						NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
						CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, openFLEX, (__bridge CFStringRef)[NSString stringWithFormat:@"FLEXivator/%@", bundleID], NULL, CFNotificationSuspensionBehaviorCoalesce);
					}
					////////////////////////////////////////
				}
			}
		}
	}
}