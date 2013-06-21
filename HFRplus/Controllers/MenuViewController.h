//
//  MenuViewController.h
//  HFRplus
//
//  Created by Shasta on 15/06/13.
//
//

#import <UIKit/UIKit.h>
@class MenuButton;

@interface MenuViewController : UIViewController <UIScrollViewDelegate>

@property (retain, nonatomic) UINavigationController *activeController;
@property (retain, nonatomic) MenuButton *activeMenu;
@property (retain, nonatomic) UINavigationController *navigationTab1Controller;

@property (retain, nonatomic) UINavigationController *forumsController;
@property (retain, nonatomic) UINavigationController *favoritesController;
@property (retain, nonatomic) UINavigationController *searchController;

@property (retain, nonatomic) IBOutlet MenuButton *btnCategories;
@property (retain, nonatomic) IBOutlet MenuButton *btnFavoris;
@property (retain, nonatomic) IBOutlet MenuButton *btnSearch;
@property (retain, nonatomic) IBOutlet MenuButton *btnTabs;

@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) UIView *containerView;
@property (retain, nonatomic) NSMutableArray *tabsViews;
@property (retain, nonatomic) IBOutlet UIView *popoverView;

- (IBAction)switchBtn:(id)sender forEvent:(UIEvent *)event;

- (void)loadTab:(id)viewController;

@end