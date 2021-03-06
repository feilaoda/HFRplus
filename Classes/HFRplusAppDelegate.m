//
//  HFRplusAppDelegate.m
//  HFRplus
//
//  Created by FLK on 18/08/10.
//  updated Branch
//

#import "HFRplusAppDelegate.h"
#import "UIAlertViewURL.h"

#import "HFRMPViewController.h"
#import "FavoritesTableViewController.h"

#import "MKStoreManager.h"
#import "BrowserViewController.h"

@implementation HFRplusAppDelegate

@synthesize window;
@synthesize rootController;
@synthesize splitViewController;
@synthesize detailNavigationController;

@synthesize forumsNavController;
@synthesize favoritesNavController;
@synthesize messagesNavController;
@synthesize searchNavController;

@synthesize isLoggedIn;
@synthesize statusChanged;

@synthesize hash_check, internetReach;

//@synthesize periodicMaintenanceOperation; //ioQueue,

#pragma mark -
#pragma mark Application lifecycle

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
    NSLog(@"reachabilityChanged:");
    
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    

    NSLog(@"didFinishLaunchingWithOptions");

    
    [TestFlight takeOff:kTestFlightAPI];
    
	//self.hash_check = [[NSString alloc] init];
	
	[MKStoreManager sharedManager];
	    
    [self registerDefaultsFromSettingsBundle];
    
	// Override point for customization after application launch.
	    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];

    internetReach = [[Reachability reachabilityForInternetConnection] retain];
	[internetReach startNotifier];
    
	rootController.customizableViewControllers = nil;

    // Start up window
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { 
        [splitViewController view].backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bgbigiPad"]];

        splitViewController.delegate = splitViewController;
        [window setRootViewController:splitViewController];

    } else {
        [window setRootViewController:rootController];
    }
    	
    [window makeKeyAndVisible];

	periodicMaintenanceTimer = [[NSTimer scheduledTimerWithTimeInterval:60*10
																 target:self
															   selector:@selector(periodicMaintenance)
															   userInfo:nil
																repeats:YES] retain];
	
    return YES;
}

- (void)registerDefaultsFromSettingsBundle {
    
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"InAppSettings" ofType:@"bundle"];
        
    if(!settingsBundle) {
        //NSLog(@"Could not find Settings.bundle");
        return;
    }
	
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.inApp.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
	
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        
        if(key && [prefSpecification objectForKey:@"DefaultValue"]) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }

    NSDictionary *settings2 = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"ActionsMessages.plist"]];
    NSArray *preferences2 = [settings2 objectForKey:@"PreferenceSpecifiers"];
	
    for(NSDictionary *prefSpecification in preferences2) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        
        if(key && [prefSpecification objectForKey:@"DefaultValue"]) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }	
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];    
    [defaultsToRegister release];
}


+ (HFRplusAppDelegate *)sharedAppDelegate
{
    return (HFRplusAppDelegate *) [UIApplication sharedApplication].delegate;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	NSLog(@"applicationDidEnterBackground");
    [periodicMaintenanceTimer invalidate];
    [periodicMaintenanceTimer release], periodicMaintenanceTimer = nil;	
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
	NSLog(@"applicationWillEnterForeground");

	periodicMaintenanceTimer = [[NSTimer scheduledTimerWithTimeInterval:60*10
																 target:self
															   selector:@selector(periodicMaintenance)
															   userInfo:nil
																repeats:YES] retain];	
}

- (void)periodicMaintenance
{
	//NSLog(@"periodicMaintenance");
	

	
	[self performSelectorInBackground:@selector(periodicMaintenanceBack) withObject:nil];
	
	

}

- (void)periodicMaintenanceBack
{
	NSAutoreleasePool * pool2;
    
    pool2 = [[NSAutoreleasePool alloc] init];
	
	//NSLog(@"periodicMaintenanceBack");

    // If another same maintenance operation is already sceduled, cancel it so this new operation will be executed after other
    // operations of the queue, so we can group more work together
    //[periodicMaintenanceOperation cancel];
    //self.periodicMaintenanceOperation = nil;

	NSFileManager *fileManager = [NSFileManager defaultManager];

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *diskCachePath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"ImageCache"] retain];

	/*NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *URLResources = [NSArray arrayWithObject:@"NSURLCreationDateKey"];
	
	
	
	//NSArray *crashReportFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[[[NSFileManager defaultManager] userLibraryURL] URLByAppendingPathComponent:@"ImageCache"] includingPropertiesForKeys:URLResources options:(NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants) error:&error];

	
	*/
	
	if (![fileManager fileExistsAtPath:diskCachePath])
	{
		//NSLog(@"createDirectoryAtPath");
		[fileManager createDirectoryAtPath:diskCachePath
								  withIntermediateDirectories:YES
												   attributes:nil
														error:NULL];
	}
	else {
		//NSLog(@"pas createDirectoryAtPath");
		
		
		NSString *directoryPath = diskCachePath;
		NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtPath:directoryPath];
		
		NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:(-60*60*24*25)];
		//NSLog(@"yesterday %@", yesterday);
		
		for (NSString *path in directoryEnumerator) {

			if ([[path pathExtension] isEqualToString:@"rtfd"]) {
				// Don't enumerate this directory.
				[directoryEnumerator skipDescendents];
			}
			else {
				
				NSDictionary *attributes = [directoryEnumerator fileAttributes];
				NSDate *CreatedDate = [attributes objectForKey:NSFileCreationDate];

				if ([yesterday earlierDate:CreatedDate] == CreatedDate) {
					//NSLog(@"%@ was created %@", path, CreatedDate);
					
					NSError *error = nil;
					if (![fileManager removeItemAtURL:[NSURL fileURLWithPath:[diskCachePath stringByAppendingPathComponent:path]] error:&error]) {
						// Handle the error.
						//NSLog(@"error %@ %@", path, error);
					}
					
				}
				else {
					//NSLog(@"%@ was created == %@", path, CreatedDate);

				}
			}
			
		}
		
		/*
		NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
											 enumeratorAtURL:directoryURL
											 includingPropertiesForKeys:keys
											 options:(NSDirectoryEnumerationSkipsPackageDescendants |
													  NSDirectoryEnumerationSkipsHiddenFiles)
											 errorHandler:^(NSURL *url, NSError *error) {
												 // Handle the error.
												 // Return YES if the enumeration should continue after the error.
												 return YES;
											 }];
		
		for (NSURL *url in enumerator) {
		}
		 */
	}
	

	
    // If disk usage outrich capacity, run the cache eviction operation and if cacheInfo dictionnary is dirty, save it in an operation
	/* if (diskCacheUsage > self.diskCapacity)
    {
        self.periodicMaintenanceOperation = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(balanceDiskUsage) object:nil] autorelease];
        [ioQueue addOperation:periodicMaintenanceOperation];
    }*/
	//NSLog(@"end");
    [diskCachePath release];
	[pool2 drain];

}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    NSLog(@"applicationDidBecomeActive");

}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	
	
}

- (void)updateMPBadgeWithString:(NSString *)badgeValue;
{
	//NSLog(@"%@ - %d", badgeValue, [badgeValue intValue]);
    dispatch_async(dispatch_get_main_queue(), 
                  ^{  	
        if ([badgeValue intValue] > 0) {
            [[[[[self rootController] tabBar] items] objectAtIndex:2] setBadgeValue:badgeValue];
        }
        else {
            [[[[[self rootController] tabBar] items] objectAtIndex:2] setBadgeValue:nil];
            
        }
                  });
}

- (void)readMPBadge;
{
	//NSLog(@"%@ - %d", badgeValue, [badgeValue intValue]);
    dispatch_async(dispatch_get_main_queue(), 
                  ^{ 	
	NSString *badgeValue = [[[[[self rootController] tabBar] items] objectAtIndex:2] badgeValue];
	
	if ( ([badgeValue intValue] - 1) > 0) {
		[self updateMPBadgeWithString:[NSString stringWithFormat:@"%d", [badgeValue intValue] - 1]];
	}
	else {
		[[[[[self rootController] tabBar] items] objectAtIndex:2] setBadgeValue:nil];
	}
                  });	
}


- (void)openURL:(NSString *)stringUrl
{
	//NSLog(@"stringUrl %@", stringUrl);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *web = [defaults stringForKey:@"default_web"];
	
    //NSLog(@"display %@", display);
    
	if ([web isEqualToString:@"internal"]) {
        BrowserViewController *browserViewController = [[BrowserViewController alloc]
                                                        initWithNibName:@"BrowserViewController" bundle:nil];
        browserViewController.delegate = self.rootController;
        
        [self.rootController presentModalViewController:browserViewController animated:YES];
        [browserViewController.myWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:stringUrl]]];
        
        // The navigation controller is now owned by the current view controller
        // and the root view controller is owned by the navigation controller,
        // so both objects should be released to prevent over-retention.
        [browserViewController release];
        
    }
    else {
        NSString *msg = [NSString stringWithFormat:@"Vous allez quitter HFR+ et être redirigé vers :\n %@\n", stringUrl];
        
        UIAlertViewURL *alert = [[UIAlertViewURL alloc] initWithTitle:@"Attention !" message:msg
                                                             delegate:self cancelButtonTitle:@"Annuler" otherButtonTitles:@"Confirmer", nil];
        [alert setStringURL:stringUrl];
        
        [alert show];
        [alert release];  
    }
    

}

- (void)alertView:(UIAlertViewURL *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) {
        
        NSURL *tURLbase = [NSURL URLWithString:[alertView stringURL]];
        NSURL *tURL = [NSURL URLWithString:[alertView stringURL]];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *web = [defaults stringForKey:@"default_web"];
        
        if ([web isEqualToString:@"googlechrome"]) {
            NSRange rangeOfScheme = [[tURLbase absoluteString] rangeOfString:[tURLbase scheme]];
            tURL = [NSURL URLWithString:[[tURLbase absoluteString] stringByReplacingCharactersInRange:rangeOfScheme withString:web]];
        }
        
        if ([[UIApplication sharedApplication] canOpenURL:tURL]) {
            [[UIApplication sharedApplication] openURL:tURL];
        }
        else {
            [[UIApplication sharedApplication] openURL:tURLbase];
        }
		
	}
}

- (void)login
{
	if (![self isLoggedIn]) {
		[self setStatusChanged:YES];
	}
	[self setIsLoggedIn:YES];

}

- (void)logout
{
	if ([self isLoggedIn]) {
		
		[self setStatusChanged:YES];
		[self updateMPBadgeWithString:nil]; //reset MP Badge
		
        [self resetApp];
        
		[(FavoritesTableViewController *)[favoritesNavController visibleViewController] reset];
		[(HFRMPViewController *)[messagesNavController visibleViewController] reset];
 
	}
	
	[self setIsLoggedIn:NO];	
}

- (void)resetApp {
    //NSLog(@"resetApp");
    
    [forumsNavController popToRootViewControllerAnimated:NO];
    [favoritesNavController popToRootViewControllerAnimated:NO];
    [messagesNavController popToRootViewControllerAnimated:NO];
    [searchNavController popToRootViewControllerAnimated:NO];
    
    
    //[[[[[HFRplusAppDelegate sharedAppDelegate] splitViewController] viewControllers] objectAtIndex:1] popToRootViewControllerAnimated:NO];
    
    UIViewController * uivc = [[[UIViewController alloc] init] autorelease];
    uivc.title = @"HFR+";
    
    [[[HFRplusAppDelegate sharedAppDelegate] detailNavigationController] setViewControllers:[NSMutableArray arrayWithObjects: uivc, nil] animated:NO];

}

#pragma mark -
#pragma mark login management

- (void)checkLogin {
	NSLog(@"checkLogin");
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
	//NSLog(@"mem warning %@ %@", self, NSStringFromSelector(_cmd));
}

- (void)dealloc {
    [periodicMaintenanceTimer invalidate];
    [periodicMaintenanceTimer release], periodicMaintenanceTimer = nil;
    //[periodicMaintenanceOperation release], periodicMaintenanceOperation = nil;
	//[ioQueue release], ioQueue = nil;
    
	[rootController release];
    self.splitViewController = nil;
    
	[forumsNavController release];
	[favoritesNavController release];
	[messagesNavController release];
	
	self.hash_check = nil;
	
    [window release];
    [super dealloc];
}


@end
