//
//  MenuViewController.m
//  HFRplus
//
//  Created by Shasta on 15/06/13.
//
//

#import "MenuViewController.h"
#import "WEPopoverController.h"
#import <QuartzCore/QuartzCore.h>

@interface MenuViewController ()

@end

@implementation MenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSLog(@"VDL");
    //[UIColor colorWithRed:242/255.f green:144/255.f blue:27/255.f alpha:1.0f]
    
    /*
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIFont boldSystemFontOfSize:15.0], UITextAttributeFont,
                                               [UIColor colorWithRed:170/255.f green:170/255.f blue:170/255.f alpha:1.0f],UITextAttributeTextColor,
                                               [UIColor whiteColor], UITextAttributeTextShadowColor,
                                               [NSValue valueWithUIOffset:UIOffsetMake(-2, -1)], UITextAttributeTextShadowOffset, nil];
    
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:3.0f forBarMetrics:UIBarMetricsDefault];
    
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"grey_dot"] forBarMetrics:UIBarMetricsDefault];

    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"back_on"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 20.0f, 0.0f, 5.0f) resizingMode:UIImageResizingModeStretch]
                                                      forState:UIControlStateNormal
                                                    barMetrics:UIBarMetricsDefault];
        
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[UIImage imageNamed:@"back"]
                                                      forState:UIControlStateHighlighted
                                                    barMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor colorWithRed:170/255.f green:170/255.f blue:170/255.f alpha:1.0f], UITextAttributeTextColor,
      [UIColor whiteColor], UITextAttributeTextShadowColor,
      [NSValue valueWithUIOffset:UIOffsetMake(-2, 0)], UITextAttributeTextShadowOffset,
      [UIFont boldSystemFontOfSize:12], UITextAttributeFont,
      nil]
                                                forState:UIControlStateHighlighted];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor], UITextAttributeTextShadowColor,
      [NSValue valueWithUIOffset:UIOffsetMake(-2, 0)], UITextAttributeTextShadowOffset,
      [UIColor colorWithRed:242/255.f green:144/255.f blue:27/255.f alpha:1.0f], UITextAttributeTextColor,
      [UIFont boldSystemFontOfSize:12], UITextAttributeFont,
      nil]
                                                forState:UIControlStateNormal];
        
    */
    
    //[self.menuView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"pw_maze_black"]]];
    self.menuView.layer.masksToBounds = NO;
    //self.menuView.layer.cornerRadius = 8; // if you like rounded corners
    self.menuView.layer.shadowOffset = CGSizeMake(0, -1);
    self.menuView.layer.shadowRadius = 0.5;
    self.menuView.layer.shadowOpacity = 0.3;
    
    // scrollView init
    _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320 * 2 + 20 * 3, 436 * 2 + 20 * 3)];
    
    int nbTab = 4;
    int x = 20, y = 20;
    _tabsViews = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < nbTab; i++) {
        
        UIView *tabView = [[UIView alloc] initWithFrame:CGRectMake(x, y, 320, 436)];
        tabView.backgroundColor = [UIColor whiteColor];
        tabView.autoresizesSubviews = YES;
        [tabView setContentMode:UIViewContentModeScaleToFill];
        tabView.clipsToBounds = YES;
        //[tabView setUserInteractionEnabled:NO];
        
        UIView *tabtouchView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 436)];
        tabtouchView.backgroundColor = [UIColor darkGrayColor];
        tabtouchView.alpha = .8;
        tabtouchView.tag = i+1;
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(oneTap:)];
        [singleTap setNumberOfTapsRequired:1];
        [singleTap setNumberOfTouchesRequired:1];
        [tabtouchView addGestureRecognizer:singleTap];
        
        [tabView addSubview:tabtouchView];
        
        [_containerView addSubview:tabView];
        [_tabsViews addObject:tabView];
        
        x += 340;
        
        NSLog(@"i = %d |  mod %d", i, i%2);
        
        if (i%2) {
            x = 20;
            y+= 456;
        }
        
    }
    [_scrollView addSubview:_containerView];

    _scrollView.contentSize = CGSizeMake(320 * 2 + 20 * 3, 436 * 2 + 20 * 3);
 
    CGRect scrollViewFrame = _scrollView.frame;
    CGFloat scaleWidth = scrollViewFrame.size.width / _scrollView.contentSize.width;
    CGFloat scaleHeight = scrollViewFrame.size.height / _scrollView.contentSize.height;

    
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    
    _scrollView.minimumZoomScale = minScale;
    _scrollView.maximumZoomScale = minScale;//0.3835f;
    _scrollView.zoomScale = minScale;
    
    [self centerScrollViewContents];
    
    //NSLog(@"_tabsViews %@", _tabsViews);
    

    

}


- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"viewDidAppear %d", animated);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	int tab = [[defaults stringForKey:@"default_tab"] integerValue];
    
	switch (tab) {
        case 1:
            [self.btnFavoris sendActionsForControlEvents:UIControlEventTouchUpInside];
            break;
            
        default:
            [self.btnCategories sendActionsForControlEvents:UIControlEventTouchUpInside];
            break;
    }
    
}

-(void)zoomToView:(UIView *)view {
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         CGPoint newOffset;
                         newOffset.x = [view superview].frame.origin.x;
                         newOffset.y = [view superview].frame.origin.y;
                         
                         newOffset.x += _containerView.frame.origin.x;
                         newOffset.y += _containerView.frame.origin.y;
                         
                         NSLog(@"offset %@", NSStringFromCGPoint(newOffset));
                         
                         
                         _scrollView.maximumZoomScale = 1;
                         _scrollView.zoomScale = 1;
                         _scrollView.contentOffset = newOffset;
                         [view setAlpha:0];
                     }
                     completion:^(BOOL finished){
                         
                         NSLog(@"finish");
                     }];

}

-(void)oneTap:(UITapGestureRecognizer *)sender {
    NSLog(@"oneTap %@", sender.view);
    [self zoomToView:sender.view];
}

- (void)centerScrollViewContents {
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.containerView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    
    _containerView.frame = contentsFrame;
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // Return the view that we want to zoom
    return _containerView;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (WEPopoverContainerViewProperties *)improvedContainerViewProperties {
	
	WEPopoverContainerViewProperties *props = [WEPopoverContainerViewProperties alloc];
	NSString *bgImageName = nil;
	CGFloat bgMargin = 0.0;
	CGFloat bgCapSize = 0.0;
	CGFloat contentMargin = 4.0;
	
	bgImageName = @"popoverBg.png";
	
	// These constants are determined by the popoverBg.png image file and are image dependent
	bgMargin = 4; // margin width of 13 pixels on all sides popoverBg.png (62 pixels wide - 36 pixel background) / 2 == 26 / 2 == 13
	bgCapSize = 23; // ImageSize/2  == 62 / 2 == 31 pixels 46/2 = 23
	
	props.leftBgMargin = bgMargin;
	props.rightBgMargin = bgMargin;
	props.topBgMargin = bgMargin;
	props.bottomBgMargin = bgMargin;
	props.leftBgCapSize = bgCapSize;
	props.topBgCapSize = bgCapSize;
	props.bgImageName = bgImageName;
	props.leftContentMargin = contentMargin;
	props.rightContentMargin = contentMargin - 1; // Need to shift one pixel for border to look correct
	props.topContentMargin = contentMargin;
	props.bottomContentMargin = contentMargin;
	
	props.arrowMargin = 20;
	
	props.upArrowImageName = @"popoverArrowUp.png";
	props.downArrowImageName = @"popoverArrowDown.png";
	props.leftArrowImageName = @"popoverArrowLeft.png";
	props.rightArrowImageName = @"popoverArrowRight.png";
	return props;
}


- (IBAction)switchBtn:(MenuButton *)sender forEvent:(UIEvent *)event {
    NSLog(@"switchBtn");
    
    NSLog(@"_tabsViews %@", _tabsViews);

    BOOL add = NO;


    
    // Statut du bouton switch-like on/off
    if ([sender isSelected]) {
        NSLog(@"OFF");
        [sender setHighlighted:NO];
        [sender setSelected:NO];
        //_activeMenu = nil;
    }
    else
    {
        add = YES;
        [sender setHighlighted:NO];
        [sender setSelected:YES];
        //_activeMenu = sender;
    }
    
    NSLog(@"sender      %@", sender);
    NSLog(@"_activeMenu %@", _activeMenu);    
    
    //  Desactiver le bouton actif //TODO
    if (_activeMenu && sender != _activeMenu) {
        NSLog(@"desactiver ancien");
        [_activeMenu sendActionsForControlEvents:UIControlEventTouchUpInside];

    }
    
    // Action pour chaque bouton
    if (!add) {
        NSLog(@"REMOVE");
        
        _activeMenu = nil;
        
        [_activeController.view removeFromSuperview];
        [_popoverView setHidden:YES];
        
        //[_activeController removeFromParentViewController];
        //[_popoverView dismissPopoverAnimated:YES];
        //_popoverView = nil;
    }
    else
    {
        _activeMenu = sender;
        UINavigationController *navigationController;
        
        if (sender == self.btnCategories) {
            NSLog(@"== btnCategories");
            
            if (!_forumsController) {
                ForumsTableViewController *forumsViewController = [[ForumsTableViewController alloc] initWithNibName:@"ForumsTableViewController" bundle:nil];
                navigationController = [[UINavigationController alloc] initWithRootViewController:forumsViewController];

                

                
                //[navigationController.navigationBar setTintColor:[UIColor colorWithRed:242/255.f green:144/255.f blue:27/255.f alpha:1.0]];
                
                _forumsController = navigationController;
                
                [self addChildViewController:_forumsController];
            }
            else
                navigationController = _forumsController;
            
            //UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

            
//            [navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"categories_on"] forBarMetrics:UIBarMetricsDefault];
            //[self addChildViewController:navigationController];
            
            //NSLog(@"subs B %@", [[_tabsViews objectAtIndex:0] subviews]);
            
            //[[_tabsViews objectAtIndex:0] insertSubview:_forumsController.view belowSubview:[[[_tabsViews objectAtIndex:0] subviews] objectAtIndex:0]];
            
//            [navigationController didMoveToParentViewController:self];

            /*
            _popoverView = [[WEPopoverController alloc] initWithContentViewController:navigationController];
            
            //if ([_popoverView respondsToSelector:@selector(setContainerViewProperties:)]) {
                //[_popoverView setContainerViewProperties:[self improvedContainerViewProperties]];
            //}
            
            _popoverView.passthroughViews = [NSArray arrayWithObject:self.menuView];
            
            [_popoverView presentPopoverFromRect:sender.frame
                                                    inView:self.menuView
                                  permittedArrowDirections:UIPopoverArrowDirectionDown
                                                  animated:YES];
            
            */
            [navigationController didMoveToParentViewController:self];
            [_popoverView addSubview:navigationController.view];

            _activeController = navigationController;
            [_popoverView setHidden:NO];

        }
        else if (sender == self.btnFavoris) {
            NSLog(@"== btnFavoris");
            
            if (!_favoritesController) {            
                FavoritesTableViewController *favoritesViewController = [[FavoritesTableViewController alloc] initWithNibName:@"FavoritesTableViewController" bundle:nil];
                navigationController = [[UINavigationController alloc] initWithRootViewController:favoritesViewController];

                _favoritesController = navigationController;
                
                
                [self addChildViewController:_favoritesController];
                
                //[[_tabsViews objectAtIndex:0] addSubview:navigationController.view];

            }
            else
                navigationController = _favoritesController;
            
            //[navigationController didMoveToParentViewController:self];
            /*
            _popoverView = [[WEPopoverController alloc] initWithContentViewController:navigationController];

            _popoverView.passthroughViews = [NSArray arrayWithObject:self.menuView];
            
            [_popoverView presentPopoverFromRect:sender.frame
                                          inView:self.menuView
                        permittedArrowDirections:UIPopoverArrowDirectionDown
                                        animated:YES];
            */
            //[_popoverView addSubview:navigationController.view];
            _activeController = navigationController;
            //[_popoverView setHidden:NO];
            
        }
        else if (sender == self.btnSearch) {
            NSLog(@"== btnSearch");
            
            if (!_searchController) {
                HFRSearchViewController *searchViewController = [[HFRSearchViewController alloc] initWithNibName:@"HFRSearchViewController" bundle:nil];
                navigationController = [[UINavigationController alloc] initWithRootViewController:searchViewController];
                
                _searchController = navigationController;
                
                [self addChildViewController:_searchController];
            }
            else
                navigationController = _searchController;
            
            //[navigationController didMoveToParentViewController:self];
            /*
            _popoverView = [[WEPopoverController alloc] initWithContentViewController:navigationController];
            
            _popoverView.passthroughViews = [NSArray arrayWithObject:self.menuView];
            
            [_popoverView presentPopoverFromRect:self.btnSearch.frame
                                          inView:self.menuView
                        permittedArrowDirections:UIPopoverArrowDirectionDown
                                        animated:YES];
            */
            
            //[_popoverView addSubview:navigationController.view];
            _activeController = navigationController;
            //[_popoverView setHidden:NO];
            
        }
        else if (sender == self.btnTabs) {
            NSLog(@"== btnSearch");
            
            CGRect scrollViewFrame = _scrollView.frame;
            CGSize cz = CGSizeMake(320 * 2 + 20 * 3, 436 * 2 + 20 * 3);
            CGFloat scaleWidth = scrollViewFrame.size.width / cz.width;
            CGFloat scaleHeight = scrollViewFrame.size.height / cz.height;
            
            CGFloat minScale = MIN(scaleWidth, scaleHeight);
            if (_scrollView.zoomScale != minScale) {
                    
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration: .5];
                _scrollView.maximumZoomScale = minScale;
                _scrollView.zoomScale = minScale;
                _scrollView.contentOffset = CGPointMake(0, 0);
                
                for (UIView *view in _tabsViews) {
                    if ([view subviews].count == 2) {
                        NSLog(@"[view subviews] %@", [view subviews]);
                        
                        UIView* tapView = [[view subviews] objectAtIndex:1];
                        if (tapView.alpha == 0) {
                            NSLog(@"sds");
                            tapView.alpha = .8;
                        }
                    }
                }
                [UIView commitAnimations];
            }

             [_popoverView setHidden:YES];
            //[_popoverView dismissPopoverAnimated:YES];
            //_popoverView = nil;

            
        }
        
        NSLog(@"frame %@", NSStringFromCGRect(sender.frame));

    }

    /*
     //navigationController.navigationBar.alpha = .95;
     //navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
     //navigationController.navigationBar.translucent = YES;
     */
    
    
}

- (void)loadTab:(id)viewController
{
    NSLog(@"loadTab %@", viewController);
    
    if ([[_tabsViews objectAtIndex:0] subviews].count == 2) {
        [_navigationTab1Controller removeFromParentViewController];
        [_navigationTab1Controller.view removeFromSuperview];
    }
    
    _navigationTab1Controller = [[UINavigationController alloc] initWithRootViewController:viewController];
    [_navigationTab1Controller.navigationBar setBackgroundImage:[UIImage imageNamed:@"black_dot"] forBarMetrics:UIBarMetricsDefault];
    

    


    [self addChildViewController:_navigationTab1Controller];

    NSLog(@"subs B %@", [[_tabsViews objectAtIndex:0] subviews]);

    _navigationTab1Controller.view.frame = ((UIView *)[[[_tabsViews objectAtIndex:0] subviews] objectAtIndex:0]).frame;
    [[_tabsViews objectAtIndex:0] insertSubview:_navigationTab1Controller.view belowSubview:[[[_tabsViews objectAtIndex:0] subviews] objectAtIndex:0]];
    [self.btnTabs sendActionsForControlEvents:UIControlEventTouchUpInside];
    [self zoomToView:[[[_tabsViews objectAtIndex:0] subviews] objectAtIndex:1]];

    
    

    NSLog(@"subs A %@", [[_tabsViews objectAtIndex:0] subviews]);
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    NSLog(@"shouldAutorotateToInterfaceOrientation");

	// Get user preference
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *enabled = [defaults stringForKey:@"landscape_mode"];
    
	if ([enabled isEqualToString:@"all"]) {
		return YES;
	} else {
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
	}
	
}

/* for iOS6 support */
- (NSUInteger)supportedInterfaceOrientations
{
    NSLog(@"supportedInterfaceOrientations");
    
	if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"landscape_mode"] isEqualToString:@"all"]) {
        //NSLog(@"All");
        
		return UIInterfaceOrientationMaskAll;
	} else {
        //NSLog(@"Portrait");
        
		return UIInterfaceOrientationMaskPortrait;
	}
}

@end
