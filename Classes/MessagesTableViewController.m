//
//  MessagesTableViewController.m
//  HFR+
//
//  Created by Lace on 07/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <unistd.h>

#import "MessagesTableViewController.h"
#import "MessageDetailViewController.h"

#import "RegexKitLite.h"
#import "HTMLParser.h"
#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"

#import "ShakeView.h"
//#import "UIImageView+WebCache.h"
#import "RangeOfCharacters.h"
#import "NSData+Base64.h"
#import "HFRMenuItem.h"
#import "LinkItem.h"
#import <CommonCrypto/CommonDigest.h>

@implementation MessagesTableViewController
@synthesize loaded, isLoading, topicName, topicAnswerUrl, loadingView, messagesWebView, arrayData, newArrayData, detailViewController;
@synthesize swipeLeftRecognizer, swipeRightRecognizer;

@synthesize queue; //v3
@synthesize stringFlagTopic;
@synthesize editFlagTopic;
@synthesize arrayInputData;
@synthesize aToolbar;

@synthesize isFavoritesOrRead, isRedFlagged, isUnreadable, isAnimating;

@synthesize request, arrayAction, curPostID;

@synthesize firstDate;

#pragma mark -
#pragma mark Data lifecycle


- (void)cancelFetchContent
{
	[request cancel];
}

- (void)fetchContent
{
//	NSLog(@"fetchContent");
	
	[ASIHTTPRequest setDefaultTimeOutSeconds:kTimeoutMaxi];

	[self setRequest:[ASIHTTPRequest requestWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"%@%@", kForumURL, [self currentUrl]]stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]]];
	[request setDelegate:self];

	//[request setCachePolicy:ASIReloadIfDifferentCachePolicy];
	//[request setDownloadCache:[ASIDownloadCache sharedCache]];
	
	[request setDidStartSelector:@selector(fetchContentStarted:)];
	[request setDidFinishSelector:@selector(fetchContentComplete:)];
	[request setDidFailSelector:@selector(fetchContentFailed:)];

	[self.view removeGestureRecognizer:swipeLeftRecognizer];
	[self.view removeGestureRecognizer:swipeRightRecognizer];
	
	[self.messagesWebView setHidden:YES];
	[self.loadingView setHidden:NO];


	[request startAsynchronous];
}

- (void)fetchContentStarted:(ASIHTTPRequest *)theRequest
{
	//--
	//NSLog(@"fetchContentStarted");

}

- (void)fetchContentComplete:(ASIHTTPRequest *)theRequest
{
	//NSLog(@"fetchContentComplete Message");
	
	// create the queue to run our ParseOperation
    self.queue = [[NSOperationQueue alloc] init];

    // create an ParseOperation (NSOperation subclass) to parse the RSS feed data so that the UI is not blocked
    // "ownership of appListData has been transferred to the parse operation and should no longer be
    // referenced in this thread.
    //
    ParseMessagesOperation *parser = [[ParseMessagesOperation alloc] initWithData:[request responseData] index:0 reverse:NO delegate:self];
	
    [queue addOperation:parser]; // this will start the "ParseOperation"
    
    [parser release];
}

- (void)fetchContentFailed:(ASIHTTPRequest *)theRequest
{
	
	[self.loadingView setHidden:YES];
	
	//NSLog(@"theRequest.error %@", theRequest.error);
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ooops !" message:[theRequest.error localizedDescription]
												   delegate:self cancelButtonTitle:@"Annuler" otherButtonTitles:@"Réessayer", nil];
	[alert show];
	[alert release];	
}

#pragma mark -
#pragma mark View lifecycle


-(void)setupScrollAndPage
{
	//NSLog(@"url: %@", self.topicUrl);
	
	//On vire le '#t09707987987'
	NSRange rangeFlagPage;
	rangeFlagPage =  [[self currentUrl] rangeOfString:@"#" options:NSBackwardsSearch];
	
		
	if (!(rangeFlagPage.location == NSNotFound)) {
		self.stringFlagTopic = [[self currentUrl] substringFromIndex:rangeFlagPage.location];

		self.currentUrl = [[self currentUrl] substringToIndex:rangeFlagPage.location];
		//NSLog(@"stringFlagTopic = %@", stringFlagTopic);
		
	}
	else {
		self.stringFlagTopic = @"";

	}	
	//--

	//On check si y'a page=2323
	NSString *regexString  = @".*page=([^&]+).*";
	NSRange   matchedRange;// = NSMakeRange(NSNotFound, 0UL);
	NSRange   searchRange = NSMakeRange(0, self.currentUrl.length);
	NSError  *error2        = NULL;
	
	matchedRange = [self.currentUrl rangeOfRegex:regexString options:RKLNoOptions inRange:searchRange capture:1L error:&error2];
	
	if (matchedRange.location == NSNotFound) {
		NSRange rangeNumPage =  [[self currentUrl] rangeOfCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] options:NSBackwardsSearch];
		self.pageNumber = [[self.currentUrl substringWithRange:rangeNumPage] intValue];
	}
	else {
		self.pageNumber = [[self.currentUrl substringWithRange:matchedRange] intValue];
		
	}
	//On check si y'a page=2323

	[(UILabel *)[self navigationItem].titleView setText:[NSString stringWithFormat:@"%@ — %d", self.topicName, self.pageNumber]];
	//[self navigationItem].titleView.frame = CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height - 4);
	
}

-(void)setupPageToolbar:(HTMLNode *)bodyNode;
{
	//NSLog(@"setupPageToolbar");
	
	HTMLNode * pagesTrNode = [bodyNode findChildWithAttribute:@"class" matchingName:@"fondForum2PagesHaut" allowPartial:YES];
	
	if(pagesTrNode)
	{		
		HTMLNode * pagesLinkNode = [pagesTrNode findChildWithAttribute:@"class" matchingName:@"left" allowPartial:NO];
		
		if (pagesLinkNode) {
			//NSLog(@"pages");
			
			//NSArray *temporaryNumPagesArray = [[NSArray alloc] init];
			NSArray *temporaryNumPagesArray = [pagesLinkNode children];
			
			
			[self setFirstPageNumber:[[[temporaryNumPagesArray objectAtIndex:2] contents] intValue]];
			
			if ([self pageNumber] == [self firstPageNumber]) {
				NSString *newFirstPageUrl = [[NSString alloc] initWithString:[self currentUrl]];
				[self setFirstPageUrl:newFirstPageUrl];
				[newFirstPageUrl release];
			}
			else {
				NSString *newFirstPageUrl = [[NSString alloc] initWithString:[[temporaryNumPagesArray objectAtIndex:2] getAttributeNamed:@"href"]];
				[self setFirstPageUrl:newFirstPageUrl];
				[newFirstPageUrl release];
			}
			
			[self setLastPageNumber:[[[temporaryNumPagesArray lastObject] contents] intValue]];
			
			if ([self pageNumber] == [self lastPageNumber]) {
				NSString *newLastPageUrl = [[NSString alloc] initWithString:[self currentUrl]];
				[self setLastPageUrl:newLastPageUrl];
				[newLastPageUrl release];
			}
			else {
				NSString *newLastPageUrl = [[NSString alloc] initWithString:[[temporaryNumPagesArray lastObject] getAttributeNamed:@"href"]];
				[self setLastPageUrl:newLastPageUrl];
				[newLastPageUrl release];
			}
			
			/*
			 NSLog(@"premiere %d", [self firstPageNumber]);			
			 NSLog(@"premiere url %@", [self firstPageUrl]);
			 
			 NSLog(@"premiere %d", [self lastPageNumber]);			
			 NSLog(@"premiere url %@", [self lastPageUrl]);		
			 */
			
			//TableFooter
			UIToolbar *tmptoolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
			tmptoolbar.barStyle = UIBarStyleDefault;
			[tmptoolbar sizeToFit];
			
			//Add buttons
			UIBarButtonItem *systemItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
																						 target:self
																						 action:@selector(firstPage:)];
			if ([self pageNumber] == [self firstPageNumber]) {
				[systemItem1 setEnabled:NO];
			}
			
			UIBarButtonItem *systemItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward
																						 target:self
																						 action:@selector(lastPage:)];
			
			if ([self pageNumber] == [self lastPageNumber]) {
				[systemItem2 setEnabled:NO];
			}		
			
			UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 230, 44)];
			[label setFont:[UIFont boldSystemFontOfSize:15.0]];
			[label setAdjustsFontSizeToFitWidth:YES];
			[label setBackgroundColor:[UIColor clearColor]];
			[label setTextAlignment:UITextAlignmentCenter];
			[label setLineBreakMode:UILineBreakModeMiddleTruncation];
			[label setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
			
			[label setTextColor:[UIColor whiteColor]];
			[label setNumberOfLines:0];
			[label setTag:666];
			[label setText:[NSString stringWithFormat:@"%d/%d", [self pageNumber], [self lastPageNumber]]];
			
			UIBarButtonItem *systemItem3 = [[UIBarButtonItem alloc] initWithCustomView:label];
			
			[label release];
			
			
			
			
			//Use this to put space in between your toolbox buttons
			UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																					  target:nil
																					  action:nil];
			
			//Add buttons to the array
			NSArray *items = [NSArray arrayWithObjects: systemItem1, flexItem, systemItem3, flexItem, systemItem2, nil];
			
			//release buttons
			[systemItem1 release];
			[systemItem2 release];
			[systemItem3 release];
			[flexItem release];
			
			//add array of buttons to toolbar
			[tmptoolbar setItems:items animated:NO];
			
			self.aToolbar = tmptoolbar;
			[tmptoolbar release];
			
		}
		else {
			self.aToolbar = nil;
			//NSLog(@"pas de pages");
			
		}
		
		
		
		//--
		
		
		//NSArray *temporaryPagesArray = [[NSArray alloc] init];
		
		NSArray *temporaryPagesArray = [pagesTrNode findChildrenWithAttribute:@"class" matchingName:@"pagepresuiv" allowPartial:YES];
		
		if(temporaryPagesArray.count != 3)
		{
			//NSLog(@"pas 3");
			//[self.view removeGestureRecognizer:swipeLeftRecognizer];
			//[self.view removeGestureRecognizer:swipeRightRecognizer];
		}
		else {
			HTMLNode *nextUrlNode = [[temporaryPagesArray objectAtIndex:0] findChildWithAttribute:@"class" matchingName:@"cHeader" allowPartial:NO];
			
			if (nextUrlNode) {
				//nextPageUrl = [[NSString stringWithFormat:@"%@", [topicUrl stringByReplacingCharactersInRange:rangeNumPage withString:[NSString stringWithFormat:@"%d", (pageNumber + 1)]]] retain];
				//nextPageUrl = [[NSString stringWithFormat:@"%@", [topicUrl stringByReplacingCharactersInRange:rangeNumPage withString:[NSString stringWithFormat:@"%d", (pageNumber + 1)]]] retain];
				[self.view addGestureRecognizer:swipeLeftRecognizer];
				self.nextPageUrl = [[nextUrlNode getAttributeNamed:@"href"] copy];
				//NSLog(@"nextPageUrl = %@", nextPageUrl);
				
			}
			else {
				self.nextPageUrl = @"";
				//[self.view removeGestureRecognizer:swipeLeftRecognizer];
			}
			
			HTMLNode *previousUrlNode = [[temporaryPagesArray objectAtIndex:1] findChildWithAttribute:@"class" matchingName:@"cHeader" allowPartial:NO];
			
			if (previousUrlNode) {
				//previousPageUrl = [[topicUrl stringByReplacingCharactersInRange:rangeNumPage withString:[NSString stringWithFormat:@"%d", (pageNumber - 1)]] retain];
				[self.view addGestureRecognizer:swipeRightRecognizer];
				self.previousPageUrl = [[previousUrlNode getAttributeNamed:@"href"] copy];
				//NSLog(@"previousPageUrl = %@", previousPageUrl);
				
			}
			else {
				self.previousPageUrl = @"";
				//[self.view removeGestureRecognizer:swipeRightRecognizer];
				
				
			}
			
		}
	}
	else {
		self.aToolbar = nil;
	}
	//NSLog(@"Fin setupPageToolbar");
	
	//--Pages
}

-(void)addDataInTableView {
	[self.view removeGestureRecognizer:swipeRightRecognizer];
	[self.view removeGestureRecognizer:swipeLeftRecognizer];

	[self.newArrayData removeAllObjects];
	//int countArrayDataBefore = arrayData.count;
	
	[self setupScrollAndPage];
	
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *diskCachePath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"ImageCache"] retain];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath])
	{
		//NSLog(@"createDirectoryAtPath");
		[[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath
								  withIntermediateDirectories:YES
												   attributes:nil
														error:NULL];
	}
	else {
		//NSLog(@"pas createDirectoryAtPath");
	}
	
	
	//NSLog(@"url %@", [NSString stringWithFormat:@"http://forum.hardware.fr%@", [self topicUrl]]);
	NSError * error = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;	
	[self setIsLoading:YES];
	HTMLParser * myParser = [[HTMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kForumURL, [self currentUrl]]] error:&error];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self setIsLoading:NO];
	
	//NSLog(@"error %@", error);
	
	HTMLNode * bodyNode = [myParser body]; //Find the body tag

	//Titre
	HTMLNode *titleNode = [[bodyNode findChildWithAttribute:@"class" matchingName:@"fondForum2Title" allowPartial:YES] findChildTag:@"h3"]; //Get all the <img alt="" />
	if ([titleNode allContents]) {
		//NSLog(@"titleNode %@", [titleNode allContents]);
		self.topicName = [titleNode allContents];
		[(UILabel *)[self navigationItem].titleView setText:[NSString stringWithFormat:@"%@ — %d", self.topicName, self.pageNumber]];
		//[self navigationItem].titleView.frame = CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height - 4);
		
	}

	
	//Titre
	
	//MP
	BOOL needToUpdateMP = NO;
	HTMLNode *MPNode = [bodyNode findChildOfClass:@"none"]; //Get links for cat	
	NSArray *temporaryMPArray = [MPNode findChildTags:@"td"];
	//NSLog(@"temporaryMPArray count %d", temporaryMPArray.count);
	
	if (temporaryMPArray.count == 3) {
		//NSLog(@"MPNode allContents %@", [[temporaryMPArray objectAtIndex:1] allContents]);
		
		NSString *regExMP = @"[^.0-9]+([0-9]{1,})[^.0-9]+";			
		NSString *myMPNumber = [[[temporaryMPArray objectAtIndex:1] allContents] stringByReplacingOccurrencesOfRegex:regExMP
																										  withString:@"$1"];
		
		[[HFRplusAppDelegate sharedAppDelegate] updateMPBadgeWithString:myMPNumber];
	}
	else {
		needToUpdateMP = YES;
	}
	//MP

	[self setupFastAnswer:bodyNode]; // Formulaire reponse rapide;
	[self setupPageToolbar:bodyNode]; // toolbars numero de page et changement de page;
	
	NSArray * messagesNodes = [bodyNode findChildrenWithAttribute:@"class" matchingName:@"message cBackCouleurTab" allowPartial:YES]; //Get all the <img alt="" />
	
	//int i = 0; //curent obj number
	
	//NSLog(@"count before %d", self.arrayData.count);
	for (HTMLNode * messageNode in messagesNodes) { //Loop through all the tags

		//NSAutoreleasePool * pool3 = [[NSAutoreleasePool alloc] init];
		
		HTMLNode * authorNode = [messageNode findChildWithAttribute:@"class" matchingName:@"s2" allowPartial:NO];
		
		LinkItem *fasTest = [[LinkItem alloc] init];

		if ([[[[messageNode parent] parent] getAttributeNamed:@"class"] isEqualToString:@"messagetabledel"]) {
			fasTest.isDel = YES;
		}
		else {
			fasTest.isDel = NO;
		}
		
		fasTest.postID = [[[messageNode firstChild] firstChild] getAttributeNamed:@"name"];

		fasTest.name = [authorNode allContents];
		fasTest.name = [fasTest.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		if ([fasTest.name isEqualToString:@"Publicité"]) {
			[fasTest release];
			//[pool3 drain];
			continue;
		}
		
		//i++;
		
		//NSLog(@"i = %d -- count = %d", i, countArrayDataBefore);

		//if (countArrayDataBefore >= i) {
		//	[fasTest release];
		//	[pool3 drain];
		//	continue;
		//}

		HTMLNode * avatarNode = [messageNode findChildWithAttribute:@"class" matchingName:@"avatar_center" allowPartial:NO];
		HTMLNode * contentNode = [messageNode findChildWithAttribute:@"id" matchingName:@"para" allowPartial:YES];

		/* OLD SLOW
		 HTMLNode * quoteNode = [[messageNode findChildWithAttribute:@"alt" matchingName:@"answer" allowPartial:NO] parent];
		 NSString *linkQuoteUnCrypted = [[quoteNode className] decodeSpanUrlFromString];
		 
		 HTMLNode * editNode = [[messageNode findChildWithAttribute:@"alt" matchingName:@"edit" allowPartial:NO] parent];
		 NSString *linkEditUnCrypted = [[editNode className] decodeSpanUrlFromString];
		 
		 fasTest.urlQuote = linkQuoteUnCrypted;
		 fasTest.urlEdit = linkEditUnCrypted;
		 */
		// NEW FAST
		HTMLNode * quoteNode = [[messageNode findChildWithAttribute:@"alt" matchingName:@"answer" allowPartial:NO] parent];
		fasTest.urlQuote = [quoteNode className];
		
		HTMLNode * editNode = [[messageNode findChildWithAttribute:@"alt" matchingName:@"edit" allowPartial:NO] parent];
		fasTest.urlEdit = [editNode className];		

		HTMLNode * addFlagNode = [messageNode findChildWithAttribute:@"href" matchingName:@"addflag" allowPartial:YES];
		fasTest.addFlagUrl = [addFlagNode getAttributeNamed:@"href"];

		HTMLNode * quoteJSNode = [messageNode findChildWithAttribute:@"onclick" matchingName:@"quoter('hardwarefr'" allowPartial:YES];
		fasTest.quoteJS = [quoteJSNode getAttributeNamed:@"onclick"];

		HTMLNode * MPNode = [messageNode findChildWithAttribute:@"href" matchingName:@"/message.php?config=hfr.inc&cat=prive&sond=&p=1&subcat=&dest=" allowPartial:YES];
		fasTest.MPUrl = [MPNode getAttributeNamed:@"href"];
		
		fasTest.dicoHTML = rawContentsOfNode([contentNode _node], [myParser _doc]);
		
		//fasTest.messageNode = contentNode;
		
		HTMLNode * dateNode = [messageNode findChildWithAttribute:@"class" matchingName:@"toolbar" allowPartial:NO];
		if ([dateNode allContents]) {
			
			//fasTest.messageDate = [[[NSString stringWithFormat:@"%@", [dateNode allContents]] stringByReplacingOccurrencesOfString:@"Posté le " withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];	
			NSString *regularExpressionString = @".*([0-9]{2})-([0-9]{2})-([0-9]{4}).*([0-9]{2}):([0-9]{2}):([0-9]{2}).*";
			fasTest.messageDate = [[dateNode allContents] stringByReplacingOccurrencesOfRegex:regularExpressionString withString:@"$1-$2-$3 $4:$5:$6"];
		}
		else {
			fasTest.messageDate = @"";
		}
		
		fasTest.imageUrl = nil;
		fasTest.imageUI = nil;

		if ([[avatarNode firstChild] getAttributeNamed:@"src"]) {
			/*fasTest.imageUrl = [[avatarNode firstChild] getAttributeNamed:@"src"];*/
			
			
			 NSFileManager *fileManager = [[NSFileManager alloc] init];
			 
			 fasTest.imageUrl = [[avatarNode firstChild] getAttributeNamed:@"src"];
			 
			 //Dl
			 const char *str = [fasTest.imageUrl UTF8String];
			 unsigned char r[CC_MD5_DIGEST_LENGTH];
			 CC_MD5(str, strlen(str), r);
			 NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			 r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
			 
			 NSString *key = [diskCachePath stringByAppendingPathComponent:filename];
			 
			 if (![fileManager fileExistsAtPath:key])
			 {
			 [fileManager createFileAtPath:key contents:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", fasTest.imageUrl]]] attributes:nil];					
			 }
			 
			 fasTest.imageUI = key;
			 [fileManager release];
			 
		}
					
		//NSLog(@"La on ajoute dude");

		[self.newArrayData addObject:fasTest];
		
		[fasTest release];
	
		//[pool3 drain];
	}	
	//NSLog(@"count after %d", self.arrayData.count);

	[myParser release];
	[diskCachePath release];
}

-(void)loadDataInTableView:(HTMLParser *)myParser
{
	[self setupScrollAndPage];

	//NSLog(@"name topicName %@", self.topicName);
	
	HTMLNode * bodyNode = [myParser body]; //Find the body tag

	//MP
	BOOL needToUpdateMP = NO;
	HTMLNode *MPNode = [bodyNode findChildOfClass:@"none"]; //Get links for cat	
	NSArray *temporaryMPArray = [MPNode findChildTags:@"td"];
	//NSLog(@"temporaryMPArray count %d", temporaryMPArray.count);
	
	if (temporaryMPArray.count == 3) {
		//NSLog(@"MPNode allContents %@", [[temporaryMPArray objectAtIndex:1] allContents]);
		
		NSString *regExMP = @"[^.0-9]+([0-9]{1,})[^.0-9]+";			
		NSString *myMPNumber = [[[temporaryMPArray objectAtIndex:1] allContents] stringByReplacingOccurrencesOfRegex:regExMP
																										  withString:@"$1"];
		
		[[HFRplusAppDelegate sharedAppDelegate] updateMPBadgeWithString:myMPNumber];
	}
	else {
		needToUpdateMP = YES;
	}
	
	//MP
	
	//Answer Topic URL
	HTMLNode * topicAnswerNode = [bodyNode findChildWithAttribute:@"id" matchingName:@"repondre_form" allowPartial:NO];
	topicAnswerUrl = [[NSString alloc] init];
	topicAnswerUrl = [[[topicAnswerNode findChildTag:@"a"] getAttributeNamed:@"href"] retain];
	//NSLog(@"new answer: %@", topicAnswerUrl);
	
	//form to fast answer
	[self setupFastAnswer:bodyNode];

	if(topicAnswerUrl.length > 0) self.navigationItem.rightBarButtonItem.enabled = YES;
	//-	

	
	//--Pages	
	[self setupPageToolbar:bodyNode];

	
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andUrl:(NSString *)theTopicUrl {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		// Custom initialization
        //NSLog(@"init %@", theTopicUrl);
		self.currentUrl = [theTopicUrl copy];	
		self.loaded = NO;
		//[self refreshData];

	}
	return self;
}

- (void)viewDidLoad {
	//NSLog(@"viewDidLoad");

    [super viewDidLoad];
	self.isAnimating = NO;
	
	self.firstDate = [NSDate date];
	
	self.title = self.topicName;

	//Gesture
	UIGestureRecognizer *recognizer;
	
	//De Gauche à droite
	recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeToRight:)];
	self.swipeRightRecognizer = (UISwipeGestureRecognizer *)recognizer;
	[recognizer release];	
	
	//De Droite à gauche
	recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeToLeft:)];
	self.swipeLeftRecognizer = (UISwipeGestureRecognizer *)recognizer;
    swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    self.swipeLeftRecognizer = (UISwipeGestureRecognizer *)recognizer;
	[recognizer release];
	//-- Gesture

	//Bouton Repondre message
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(answerTopic)];
    segmentBarItem.enabled = NO;
	
	self.navigationItem.rightBarButtonItem = segmentBarItem;
    [segmentBarItem release];	

	[(ShakeView*)self.view setShakeDelegate:self];
	
	self.arrayAction = [[NSMutableArray alloc] init];
	self.arrayData = [[NSMutableArray alloc] init];
	self.newArrayData = [[NSMutableArray alloc] init];
	self.arrayInputData = [[NSMutableDictionary alloc] init];
	self.editFlagTopic = [[NSString	alloc] init];
	self.isFavoritesOrRead = [[NSString	alloc] init];
	self.isUnreadable = NO;
	self.curPostID = -1;
	
	[self setEditFlagTopic:nil];

	[self fetchContent];
	
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	//NSLog(@"viewWillDisappear");
	self.isAnimating = YES;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	//NSLog(@"viewDidAppear");
	self.isAnimating = NO;
}

-(void)answerTopic
{
	// Create the root view controller for the navigation controller
	// The new view controller configures a Cancel and Done button for the
	// navigation bar.
	
	/*
	FormViewController *formViewController = [[FormViewController alloc]
														  initWithNibName:@"FormViewController" bundle:nil];
	
	[[formViewController.viewControllers objectAtIndex:0] setDelegate:self];
	[[formViewController.viewControllers objectAtIndex:0] setArrayInputData:self.arrayInputData];

	[self presentModalViewController:formViewController animated:YES];

	[formViewController release];


	AddMessageViewController *addMessageViewController = [[AddMessageViewController alloc]
															  initWithNibName:@"AddMessageViewController" bundle:nil];
	addMessageViewController.delegate = self;
	[addMessageViewController setArrayInputData:self.arrayInputData];
*/
	
	if (self.isAnimating) {
		return;
	}
	
	NewMessageViewController *addMessageViewController = [[NewMessageViewController alloc]
														   initWithNibName:@"AddMessageViewController" bundle:nil];
	addMessageViewController.delegate = self;
	[addMessageViewController setUrlQuote:[NSString stringWithFormat:@"http://forum.hardware.fr%@", topicAnswerUrl]];
	addMessageViewController.title = @"Nouv. Réponse";
	
	
	// Create the navigation controller and present it modally.
	UINavigationController *navigationController = [[UINavigationController alloc]
													initWithRootViewController:addMessageViewController];
	[self presentModalViewController:navigationController animated:YES];
	
	// The navigation controller is now owned by the current view controller
	// and the root view controller is owned by the navigation controller,
	// so both objects should be released to prevent over-retention.
	[navigationController release];
	[addMessageViewController release];

	//[[HFR_AppDelegate sharedAppDelegate] openURL:[NSString stringWithFormat:@"http://forum.hardware.fr%@", topicAnswerUrl]];

	//[[UIApplication sharedApplication] open-URL:[NSURL URLWithString:[NSString stringWithFormat:@"http://forum.hardware.fr/%@", topicAnswerUrl]]];
	
/*
	HFR_AppDelegate *mainDelegate = (HFR_AppDelegate *)[[UIApplication sharedApplication] delegate];
	[[mainDelegate rootController] setSelectedIndex:3];		
	[[(BrowserViewController *)[[mainDelegate rootController] selectedViewController] webView] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://forum.hardware.fr/%@", topicAnswerUrl]]]];		
 */
}

-(void)quoteMessage:(NSString *)quoteUrl
{
	if (self.isAnimating) {
		return;
	}
	
	// Create the root view controller for the navigation controller
	// The new view controller configures a Cancel and Done button for the
	// navigation bar.
	/*
	QuoteFormView *formViewController = [[QuoteFormView alloc]
											  initWithNibName:@"FormViewController" bundle:nil];
	
	[[formViewController.viewControllers objectAtIndex:0] setDelegate:self];
	[[formViewController.viewControllers objectAtIndex:0] setUrlQuote:quoteUrl];
	
	[self presentModalViewController:formViewController animated:YES];
	
	[formViewController release];
 */
	
	QuoteMessageViewController *quoteMessageViewController = [[QuoteMessageViewController alloc]
														  initWithNibName:@"AddMessageViewController" bundle:nil];
	quoteMessageViewController.delegate = self;
	[quoteMessageViewController setUrlQuote:quoteUrl];
	
	// Create the navigation controller and present it modally.
	UINavigationController *navigationController = [[UINavigationController alloc]
													initWithRootViewController:quoteMessageViewController];
	[self presentModalViewController:navigationController animated:YES];
	
	// The navigation controller is now owned by the current view controller
	// and the root view controller is owned by the navigation controller,
	// so both objects should be released to prevent over-retention.
	[navigationController release];
	[quoteMessageViewController release];
	
}

-(void)editMessage:(NSString *)editUrl
{
	if (self.isAnimating) {
		return;
	}
	// Create the root view controller for the navigation controller
	// The new view controller configures a Cancel and Done button for the
	// navigation bar.
	/*
	EditFormView *formViewController = [[EditFormView alloc]
											  initWithNibName:@"FormViewController" bundle:nil];
	
	[[formViewController.viewControllers objectAtIndex:0] setDelegate:self];
	[[formViewController.viewControllers objectAtIndex:0] setUrlQuote:editUrl];
	
	[self presentModalViewController:formViewController animated:YES];
	
	[formViewController release];
	 */
	
	EditMessageViewController *editMessageViewController = [[EditMessageViewController alloc]
															  initWithNibName:@"AddMessageViewController" bundle:nil];
	editMessageViewController.delegate = self;
	[editMessageViewController setUrlQuote:editUrl];
	
	// Create the navigation controller and present it modally.
	UINavigationController *navigationController = [[UINavigationController alloc]
													initWithRootViewController:editMessageViewController];
	[self presentModalViewController:navigationController animated:YES];
	
	// The navigation controller is now owned by the current view controller
	// and the root view controller is owned by the navigation controller,
	// so both objects should be released to prevent over-retention.
	[navigationController release];
	[editMessageViewController release];
	
}



/*
- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

	//NSLog(@"toscroll, %d", messageToScroll);
}
*/
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.view becomeFirstResponder];

	//[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
	
	
	if(self.detailViewController) self.detailViewController = nil;
 
}

/*
- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
}
*/


- (void)viewDidDisappear:(BOOL)animated {
	//NSLog(@"viewDidDisappear");

    [super viewDidDisappear:animated];
	[self.view resignFirstResponder];
	
}
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	//NSLog(@"shouldAutorotateToInterfaceOrientation");
	return YES;
}

-(void)searchNewMessages {
	//NSLog(@"searchNewMessages %@", self);
	if (![self.messagesWebView isLoading]) {	
		// Register for the notification
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(messagesDataReceived:)
													 name:@"WebServiceCallCompleted" object:nil];
		//NSIndexPath* selection = [self.messagesTableView indexPathForSelectedRow];
		
		// Unhide the spinner, and start animating it.
		//[[[self loadMoreCell] activityIndicator] startAnimating];
		
		// Start the connection...
		//[NSThread detachNewThreadSelector:@selector(messagesDataStarted:) toTarget:self withObject:nil];
		[self.messagesWebView stringByEvaluatingJavaScriptFromString:@"$('#actualiserbtn').addClass('loading');"];
		
		[self performSelectorInBackground:@selector(messagesDataStarted:) withObject:nil];
		
		// Disable user interaction if/when the loading/search results view appears.
		//[self.messagesTableView setUserInteractionEnabled:NO];
		
		// Unhighlight the load more button after it has been tapped.
		//if (selection)
		//[self.messagesTableView deselectRowAtIndexPath:selection animated:YES];
		
	}	
}

- (void)didSelectMessage:(int)index
{
	{
		// Navigation logic may go here. Create and push another view controller.

		 if (self.detailViewController == nil) {
			 MessageDetailViewController *aView = [[MessageDetailViewController alloc] initWithNibName:@"MessageDetailViewControllerv2" bundle:nil];
			 self.detailViewController = aView;
			 [aView release];
		 }
		 
		 
		 // ...
		 // Pass the selected object to the new view controller.
		 self.navigationItem.backBarButtonItem =
		 [[UIBarButtonItem alloc] initWithTitle:@"Retour"
		 style: UIBarButtonItemStyleBordered
		 target:nil
		 action:nil];
		
		
		///===
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
		label.frame = CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height - 4);
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		[label setFont:[UIFont boldSystemFontOfSize:16.0]];
		[label setAdjustsFontSizeToFitWidth:YES];
		[label setBackgroundColor:[UIColor clearColor]];
		[label setTextAlignment:UITextAlignmentCenter];
		[label setLineBreakMode:UILineBreakModeMiddleTruncation];
		label.shadowColor = [UIColor darkGrayColor];
		label.shadowOffset = CGSizeMake(0.0, -1.0);
		[label setTextColor:[UIColor whiteColor]];
		[label setNumberOfLines:0];
		
		[label setText:[NSString stringWithFormat:@"Page: %d — %d/%d", self.pageNumber, index + 1, arrayData.count]];
		
		[self.detailViewController.navigationItem setTitleView:label];
		[label release];
		
		
		///===
		
		/*
		 UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 230, 44)];
		 
		 
		 UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 230, 44)];
		 [label setFont:[UIFont boldSystemFontOfSize:15.0]];
		 [label setAdjustsFontSizeToFitWidth:YES];
		 [label setBackgroundColor:[UIColor redColor]];
		 [label setTextAlignment:UITextAlignmentCenter];
		 [label setLineBreakMode:UILineBreakModeMiddleTruncation];
		 [label setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];

		 label.shadowColor = [UIColor darkGrayColor];
		 label.shadowOffset = CGSizeMake(0.0, -1.0);
		
		 [label setTextColor:[UIColor whiteColor]];
		 [label setNumberOfLines:0];
		 [label setTag:666];
		 [label setText:[NSString stringWithFormat:@"Page: %d — %d/%d", self.pageNumber, index + 1, arrayData.count]];
		 
		 [titleView insertSubview:label atIndex:1];
		 [label release];	
		 
		 [self.detailViewController.navigationItem setTitleView:titleView];
		 [titleView release];	
		 */
		
		 //setup the URL
		 //detailViewController.topicName = [[arrayData objectAtIndex:indexPath.row] name];	
		 
		 //NSLog(@"push message details");
		 // andContent:[arrayData objectAtIndex:indexPath.section]
		 
		 self.detailViewController.arrayData = arrayData;	
		 self.detailViewController.curMsg = index;	
		 self.detailViewController.pageNumber = self.pageNumber;	
		 self.detailViewController.parent = self;	
		 self.detailViewController.messageTitleString = self.topicName;	
		 
		 [self.navigationController pushViewController:detailViewController animated:YES];

	}
}

- (void) didSelectImage:(int)index withUrl:(NSString *)selectedURL {
	if (self.isAnimating) {
		return;
	}
	
	//On récupe les images du message:
	//NSLog(@"%@", [[arrayData objectAtIndex:index] toHTML:index]);
	
	HTMLParser * myParser = [[HTMLParser alloc] initWithString:[[arrayData objectAtIndex:index] toHTML:index] error:NULL];
	HTMLNode * msgNode = [myParser doc]; //Find the body tag

	NSArray * tmpImageArray =  [msgNode findChildrenWithAttribute:@"class" matchingName:@"hfrplusimg" allowPartial:NO];
	//NSLog(@"%d", [imageArray count]);
	
	NSMutableArray * imageArray = [[NSMutableArray alloc] init];
	
	for (HTMLNode * imgNode in tmpImageArray) { //Loop through all the tags
		//NSLog(@"alt %@", [imgNode getAttributeNamed:@"alt"]);
		//NSLog(@"longdesc %@", [imgNode getAttributeNamed:@"longdesc"]);		
		[imageArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[imgNode getAttributeNamed:@"alt"], [imgNode getAttributeNamed:@"longdesc"], nil]  forKeys:[NSArray arrayWithObjects:@"alt", @"longdesc", nil]]];
			
	}
	
	
	// Create the root view controller for the navigation controller
	// The new view controller configures a Cancel and Done button for the
	// navigation bar.
	
	//selectedURL = [selectedURL stringByReplacingOccurrencesOfString:@"http://hfr-rehost.net/preview/" withString:@"http://hfr-rehost.net/"];
	selectedURL = [selectedURL stringByReplacingOccurrencesOfString:@"http://hfr-rehost.net/thumb/" withString:@"http://hfr-rehost.net/preview/"];

	PhotoViewController *photoViewController = [[PhotoViewController alloc]
												initWithNibName:@"PhotoViewController" bundle:nil];
	photoViewController.delegate = self;
	[photoViewController setImageURL:selectedURL];
	[photoViewController setImageData:imageArray];
	[imageArray release];
	[self presentModalViewController:photoViewController animated:YES];
	
	// The navigation controller is now owned by the current view controller
	// and the root view controller is owned by the navigation controller,
	// so both objects should be released to prevent over-retention.
	[photoViewController release];
	[myParser release];
}

#pragma mark -
#pragma mark Gestures

-(void) shakeHappened:(ShakeView*)view
{
	if (![request inProgress] && !self.isLoading) {
		[self searchNewMessages];
	}
}

- (void)handleSwipeToLeft:(UISwipeGestureRecognizer *)recognizer {
	[self nextPage:recognizer];
}
- (void)handleSwipeToRight:(UISwipeGestureRecognizer *)recognizer {
	[self previousPage:recognizer];
}

#pragma mark -
#pragma mark Photo Delegate

- (void)photoViewControllerDidFinish:(PhotoViewController *)controller {
   // NSLog(@"photoViewControllerDidFinish");

	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark AddMessage Delegate
-(BOOL) canBeFavorite{
	if ([self isUnreadable]) {
		return NO;
	}
	
	
	return YES;
}

-(void)setupFastAnswer:(HTMLNode*)bodyNode
{
	HTMLNode * fastAnswerNode = [bodyNode findChildWithAttribute:@"name" matchingName:@"hop" allowPartial:NO];
	NSArray *temporaryInputArray = [fastAnswerNode findChildrenWithAttribute:@"type" matchingName:@"hidden" allowPartial:YES];
	
	//HTMLNode * inputNode;
	for (HTMLNode * inputNode in temporaryInputArray) { //Loop through all the tags
		//NSLog(@"inputNode: %@ - value: %@", [inputNode getAttributeNamed:@"name"], [inputNode getAttributeNamed:@"value"]);
		[self.arrayInputData setObject:[inputNode getAttributeNamed:@"value"] forKey:[inputNode getAttributeNamed:@"name"]];
		
	}
	
	self.isRedFlagged = NO;
	
	//Fav/Unread
	HTMLNode * FlagNode = [bodyNode findChildWithAttribute:@"href" matchingName:@"delflag" allowPartial:YES];
	self.isFavoritesOrRead =  @"";

	if (FlagNode) {
		self.isFavoritesOrRead = [FlagNode getAttributeNamed:@"href"];
		if ([FlagNode findChildWithAttribute:@"src" matchingName:@"flagn0.gif" allowPartial:YES]) {
			self.isRedFlagged = YES;
		}
	}
	else {
		HTMLNode * ReadNode = [bodyNode findChildWithAttribute:@"href" matchingName:@"nonlu" allowPartial:YES];
		if (ReadNode) {
			self.isFavoritesOrRead = [ReadNode getAttributeNamed:@"href"];
			self.isUnreadable = YES;			
		}
		else {
			self.isFavoritesOrRead =  @"";	
		}
	}
}
//--form to fast answer	

- (void)addMessageViewControllerDidFinish:(AddMessageViewController *)controller {
    //NSLog(@"addMessageViewControllerDidFinish %@", self.editFlagTopic);
	
	[self setEditFlagTopic:nil];
	[self dismissModalViewControllerAnimated:YES];
}

- (void)addMessageViewControllerDidFinishOK:(AddMessageViewController *)controller {
	//NSLog(@"addMessageViewControllerDidFinishOK");
	
	[self dismissModalViewControllerAnimated:YES];
	//if (self.curPostID >= 0 && self.curPostID < self.arrayData.count) {
		//NSLog(@"curid %d", self.curPostID);
		NSString *components = [[[self.arrayData objectAtIndex:0] quoteJS] substringFromIndex:7];
		components = [components stringByReplacingOccurrencesOfString:@"); return false;" withString:@""];
		components = [components stringByReplacingOccurrencesOfString:@"'" withString:@""];
		
		NSArray *quoteComponents = [components componentsSeparatedByString:@","];
		
		NSString *nameCookie = [NSString stringWithFormat:@"quotes%@-%@-%@", [quoteComponents objectAtIndex:0], [quoteComponents objectAtIndex:1], [quoteComponents objectAtIndex:2]];
		
		[self EffaceCookie:nameCookie];
	//}
	self.curPostID = -1;
	
	[self searchNewMessages];
	[self.navigationController popToViewController:self animated:NO];


}

#pragma mark -
#pragma mark Parse Operation Delegate
- (void)addDataToList:(NSString *)mystring {
	//NSLog(@"addDataToList");
	//'bottom'
	//[self.messagesWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"$('#qsdoiqjsdkjhqkjhqsdqdilkjqsd2').html( 'bottom', '%@');x$('#actualiserbtn').removeClass('loading');", mystring]];
}

- (void)messagesDataReceived:(id)object {
	
	//NSLog(@"messagesDataReceived self %@", self);
	//NSLog(@"messagesDataReceived object %@", [object object]);
	if (!(self == [object object])) return;
	
	//NSLog(@"editFlagTopic %@", self.editFlagTopic);

	if (!(self.editFlagTopic == nil)) { // On check si on vient pas d'edit un message
		self.stringFlagTopic = self.editFlagTopic; //si oui on flag sur l'ID en question
		[self setEditFlagTopic:nil];
	}
	else {
		if (self.newArrayData.count > self.arrayData.count) {
			self.stringFlagTopic = [[self.newArrayData objectAtIndex:self.arrayData.count] postID]; //si il y a plus de messages après l'update, on flag sur le premier nouveau
		}
		else {
			self.stringFlagTopic = @"#bas"; // sinon on flag en bas de la liste.
		}
	}

	//NSLog(@"stringFlagTopic %@", self.stringFlagTopic);


		[self.arrayData removeAllObjects];
		[self.arrayData addObjectsFromArray:self.newArrayData];
		[self.newArrayData removeAllObjects];
		
		NSString *tmpHTML = [[[NSString alloc] initWithString:@""] autorelease];
		
		int i;
		for (i = 0; i < [self.arrayData count]; i++) { //Loop through all the tags
			tmpHTML = [tmpHTML stringByAppendingString:[[self.arrayData objectAtIndex:i] toHTML:i]];
		}	
		
		NSString *HTMLString = [[NSString alloc] 
								initWithFormat:@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\
								<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"fr\" lang=\"fr\">\
								<head>\
								<script type='text/javascript' src='jquery.js'></script>\
								<script type='text/javascript' src='jquery.doubletap.js'></script>\
								<script type='text/javascript' src='jquery.base64.js'></script>\
								<script type='text/javascript' src='jquery.lazyload.mini.js'></script>\
								<meta name='viewport' content='width=device-width, user-scalable=no initial-scale=1.0' />\
								<link type='text/css' rel='stylesheet' href='style-liste.css'/>\
								<link type='text/css' rel='stylesheet' href='style-liste-retina.css' media='only screen and (-webkit-min-device-pixel-ratio: 2)'/>\
								</head><body>\
								<div class='bunselected' id='qsdoiqjsdkjhqkjhqsdqdilkjqsd2'>%@</div><div id='endofpage'></div><div id='endofpagetoolbar'></div><a name='bas'></a><script type='text/javascript'> function HLtxt() { var el = document.getElementById('qsdoiqjsdkjhqkjhqsdqdilkjqsd');el.className='bselected'; } function UHLtxt() { var el = document.getElementById('qsdoiqjsdkjhqkjhqsdqdilkjqsd');el.className='bunselected'; } function swap_spoiler_states(obj){var div=obj.getElementsByTagName('div');if(div[0]){if(div[0].style.visibility==\"visible\"){div[0].style.visibility='visible';}else if(div[0].style.visibility==\"hidden\"||!div[0].style.visibility){div[0].style.visibility='visible';}}} </script></body></html>", tmpHTML];
		
		NSString *path = [[NSBundle mainBundle] bundlePath];
		NSURL *baseURL = [NSURL fileURLWithPath:path];
		
		//NSLog(@"======================================================================================================");
		//NSLog(@"HTMLString %@", HTMLString);
		//NSLog(@"======================================================================================================");
		//NSLog(@"baseURL %@", baseURL);
		//NSLog(@"======================================================================================================");
		
		[self.messagesWebView loadHTMLString:HTMLString baseURL:baseURL];
		
		[self.messagesWebView setUserInteractionEnabled:YES];	
		
		[HTMLString release];
	//[tmpHTML release];
	//}
	//else {
	//	NSLog(@"messagesDataReceived KEUD");
	//}
	/*
	//[[[self loadMoreCell] activityIndicator] stopAnimating];
	
	int previousCount = self.arrayData.count;
	
	[self.arrayData addObjectsFromArray:self.newArrayData];
	
	NSString *tmpHTML = [[NSString alloc] initWithString:@""];
	
	int i;
	for (i = previousCount; i < [self.arrayData count]; i++) { //Loop through all the tags
		tmpHTML = [tmpHTML stringByAppendingString:[[self.arrayData objectAtIndex:i] toHTML:i]];
	}	

	tmpHTML = [tmpHTML stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
	
	NSLog(@"tmpHTML: %@", tmpHTML);

	NSLog(@"======================================================================");
	NSLog(@"======================================================================");

	NSLog(@"JS: %@", [NSString stringWithFormat:@"x$('#qsdoiqjsdkjhqkjhqsdqdilkjqsd2').html( 'bottom', '%@');", tmpHTML]);
	
	[self performSelectorOnMainThread:@selector(addDataToList:) withObject:tmpHTML waitUntilDone:YES];	

	
	//[self.messagesWebView stringByEvaluatingJavaScriptFromString:@"x$('.message').click(function(e){ window.location = 'oijlkajsdoihjlkjasdodetails://'+this.id; });"];
	 */
}

- (void)messagesDataStarted:(id)object {
	//NSLog(@"messagesDataStarted %@", self);

	NSAutoreleasePool * pool2;
    
    pool2 = [[NSAutoreleasePool alloc] init];
	
	[self addDataInTableView];
	//NSLog(@"messagesDataStarted OK");

	[self performSelectorOnMainThread:@selector(pushNotification:) withObject:[NSNotification notificationWithName:@"WebServiceCallCompleted" object:self] waitUntilDone:YES];
	
	[pool2 drain];
}

- (void)pushNotification:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] postNotification:aNotification];
}

// -------------------------------------------------------------------------------
//	handleLoadedApps:notif
// -------------------------------------------------------------------------------


- (void)handleLoadedApps:(NSArray *)loadedItems
{	
	[self.arrayData removeAllObjects];
	[self.arrayData addObjectsFromArray:loadedItems];


	NSString *tmpHTML = [[[NSString alloc] initWithString:@""] autorelease];
	
	int i;
	for (i = 0; i < [self.arrayData count]; i++) { //Loop through all the tags
		tmpHTML = [tmpHTML stringByAppendingString:[[self.arrayData objectAtIndex:i] toHTML:i]];
	}	

	//NSLog(@"handleLoadedApps OK");

	// Init the disk cache
	/*
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *diskCachePath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"ImageCache"] retain];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath])
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath
								  withIntermediateDirectories:YES
												   attributes:nil
														error:NULL];
	}
	
	NSLog(@"diskCachePath %@", diskCachePath);
	*/
	//<script type='text/javascript' src='jquery.lazyload.mini.js'></script>\


	//============	
	/*
	HTMLParser * myParser = [[HTMLParser alloc] initWithString:tmpHTML error:NULL];
	HTMLNode * smileNode = [myParser doc]; //Find the body tag
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *diskCachePath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"SmileCache"] retain];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath])
	{
		//NSLog(@"createDirectoryAtPath");
		[[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath
								  withIntermediateDirectories:YES
												   attributes:nil
														error:NULL];
	}
	else {
		//NSLog(@"pas createDirectoryAtPath");
	}
	
	
	NSArray * tmpImageArray =  [smileNode findChildrenWithAttribute:@"class" matchingName:@"smileycustom" allowPartial:NO];
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	for (HTMLNode * imgNode in tmpImageArray) { //Loop through all the tags
		NSString *imgUrl = [[imgNode getAttributeNamed:@"src"] stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
		//NSLog(@"imgUrl %@", imgUrl);
		
		NSString *filename = [imgUrl stringByReplacingOccurrencesOfString:@"http://forum-images.hardware.fr/" withString:@""];
		filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
		filename = [filename stringByReplacingOccurrencesOfString:@" " withString:@"-"];
		
		NSString *key = [diskCachePath stringByAppendingPathComponent:filename];
		
		//NSLog(@"key %@", key);
		
		if (![fileManager fileExistsAtPath:key])
		{
			//NSLog(@"dl %@", key);
			
			[fileManager createFileAtPath:key contents:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", [imgUrl stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]]] attributes:nil];					
		}
		
		tmpHTML = [tmpHTML stringByReplacingOccurrencesOfString:[imgNode getAttributeNamed:@"src"] withString:key];
		
	}
	[fileManager release];
	[diskCachePath release];
*/
	//============	
	
	
	NSString *HTMLString = [[NSString alloc] 
							initWithFormat:@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\
							<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"fr\" lang=\"fr\">\
							<head>\
							<script type='text/javascript' src='jquery.js'></script>\
							<script type='text/javascript' src='jquery.doubletap.js'></script>\
							<script type='text/javascript' src='jquery.base64.js'></script>\
							<meta name='viewport' content='width=device-width, user-scalable=no initial-scale=1.0' />\
							<link type='text/css' rel='stylesheet' href='style-liste.css'/>\
							<link type='text/css' rel='stylesheet' href='style-liste-retina.css' media='only screen and (-webkit-min-device-pixel-ratio: 2)'/>\
							</head><body>\
							<div class='bunselected' id='qsdoiqjsdkjhqkjhqsdqdilkjqsd2'>%@</div><div id='endofpage'></div><div id='endofpagetoolbar'></div><a name='bas'></a><script type='text/javascript'> function HLtxt() { var el = document.getElementById('qsdoiqjsdkjhqkjhqsdqdilkjqsd');el.className='bselected'; } function UHLtxt() { var el = document.getElementById('qsdoiqjsdkjhqkjhqsdqdilkjqsd');el.className='bunselected'; } function swap_spoiler_states(obj){var div=obj.getElementsByTagName('div');if(div[0]){if(div[0].style.visibility==\"visible\"){div[0].style.visibility='visible';}else if(div[0].style.visibility==\"hidden\"||!div[0].style.visibility){div[0].style.visibility='visible';}}} </script></body></html>", tmpHTML];
	
	NSString *path = [[NSBundle mainBundle] bundlePath];
	NSURL *baseURL = [NSURL fileURLWithPath:path];
	//NSLog(@"baseURL %@", baseURL);
	
	//NSLog(@"======================================================================================================");
	//NSLog(@"HTMLString %@", HTMLString);
	//NSLog(@"======================================================================================================");
	//NSLog(@"baseURL %@", baseURL);
	//NSLog(@"======================================================================================================");
	
	[self.messagesWebView loadHTMLString:HTMLString baseURL:baseURL];
	
	[self.messagesWebView setUserInteractionEnabled:YES];	

	[HTMLString release];
	//[tmpHTML release];

	
	
}
- (void)handleLoadedParser:(HTMLParser *)myParser
{
	[self loadDataInTableView:myParser];
}	

// -------------------------------------------------------------------------------
//	didFinishParsing:appList
// -------------------------------------------------------------------------------
- (void)didStartParsing:(HTMLParser *)myParser
{
	//NSLog(@"didStartParsing");

    [self performSelectorOnMainThread:@selector(handleLoadedParser:) withObject:myParser waitUntilDone:NO];
}

- (void)didFinishParsing:(NSArray *)appList
{
	//NSLog(@"didFinishParsing");

    [self performSelectorOnMainThread:@selector(handleLoadedApps:) withObject:appList waitUntilDone:NO];
	//NSLog(@"didFinishParsing 0");

    [self.queue release], self.queue = nil;
	
	//NSLog(@"didFinishParsing end");

}

#pragma mark -
#pragma mark WebView Delegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
	//NSLog(@"== webViewDidStartLoad");
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	//NSLog(@"== webViewDidFinishLoad");
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;	
	[self.messagesWebView setHidden:NO];

	//NSLog(@"== webViewDidFinishLoad %@", [NSString stringWithFormat:@"window.location.hash='%@';$('img.lazy').lazyload({ placeholder : 'blank15.gif' });$('img.lazy2').lazyload({ placeholder : 'avatar_male_gray_on_light_48x48.png' });", self.stringFlagTopic]);
//	jsString = [jsString stringByAppendingString:@"$('img.lazy').lazyload({ placeholder : 'blank15.gif' });"];
//	jsString = [jsString stringByAppendingString:@"$('img.lazy2').lazyload({ placeholder : 'avatar_male_gray_on_light_48x48.png' });"];
//	jsString = [jsString stringByAppendingString:[NSString stringWithFormat:@"window.location.hash='%@';", self.stringFlagTopic]];
//$('img.lazy').lazyload({ placeholder : 'blank15.gif' });$('img.lazy2').lazyload({ placeholder : 'avatar_male_gray_on_light_48x48.png' });	
	
	

	
	NSString *jsString = [[[NSString alloc] initWithString:@""] autorelease];


	//on ajoute le bouton actualiser si besoin
	if (([self pageNumber] == [self lastPageNumber]) || ([self lastPageNumber] == 0)) {
		//NSLog(@"premiere et unique ou dernier");
		//'before'
		jsString = [jsString stringByAppendingString:[NSString stringWithFormat:@"$('#endofpage').before('<div id=\"actualiserbtn\">Actualiser<div>');$('#actualiserbtn').click( function(){ window.location = 'oijlkajsdoihjlkjasdorefresh://data'; });"]];
		
	}
	else {
		//NSLog(@"autre");
	}
	
	jsString = [jsString stringByAppendingString:@"$('.message').addSwipeEvents().bind('doubletap', function(evt, touch) { window.location = 'oijlkajsdoihjlkjasdodetails://'+this.id; });"];
	jsString = [jsString stringByAppendingString:@"$('.header').click(function(event) { var offset = $(this).offset(); event.stopPropagation(); window.location = 'oijlkajsdoihjlkjasdopopup://'+(offset.top-window.pageYOffset)+'/'+this.parentNode.id; });"];
	
	jsString = [jsString stringByAppendingString:@"$('.hfrplusimg').click(function() { window.location = 'oijlkajsdoihjlkjasdoimbrows://'+this.title+'/'+$.base64.encode(this.alt); });"];
	//jsString = [jsString stringByAppendingString:@"$('.message').doubletap(function(event){ window.location = 'oijlkajsdoihjlkjasdodetails://'+this.id; }, function(event){  }, 400);"];
	
	//[webView stringByEvaluatingJavaScriptFromString:@"x$('.message').touchend(function(e){ x$(this).removeClass('touched'); });"];
	
	//Toolbar;
	if (self.aToolbar) {
		NSString *buttonBegin, *buttonEnd;
		NSString *buttonPrevious, *buttonNext;		
		
		if ([(UIBarButtonItem *)[self.aToolbar.items objectAtIndex:0] isEnabled]) {
			buttonBegin = [NSString stringWithString:@"<div class=\"button begin active\" ontouchstart=\"$(this).addClass(\\'hover\\')\" ontouchend=\"$(this).removeClass(\\'hover\\')\" ><a href=\"oijlkajsdoihjlkjasdoauto://begin\">begin</a></div>"];
			buttonPrevious = [NSString stringWithString:@"<div class=\"button2 begin active\" ontouchstart=\"$(this).addClass(\\'hover\\')\" ontouchend=\"$(this).removeClass(\\'hover\\')\" ><a href=\"oijlkajsdoihjlkjasdoauto://previous\">previous</a></div>"];
		}
		else {
			buttonBegin = [NSString stringWithString:@"<div class=\"button begin\"></div>"];
			buttonPrevious = [NSString stringWithString:@"<div class=\"button2 begin\"></div>"];
		}

		if ([(UIBarButtonItem *)[self.aToolbar.items objectAtIndex:4] isEnabled]) {
			buttonEnd = [NSString stringWithString:@"<div class=\"button end active\" ontouchstart=\"$(this).addClass(\\'hover\\')\" ontouchend=\"$(this).removeClass(\\'hover\\')\" ><a href=\"oijlkajsdoihjlkjasdoauto://end\">end</a></div>"];
			buttonNext = [NSString stringWithString:@"<div class=\"button2 end active\" ontouchstart=\"$(this).addClass(\\'hover\\')\" ontouchend=\"$(this).removeClass(\\'hover\\')\" ><a href=\"oijlkajsdoihjlkjasdoauto://next\">next</a></div>"];
		}
		else {
			buttonEnd = [NSString stringWithString:@"<div class=\"button end\"></div>"];
			buttonNext = [NSString stringWithString:@"<div class=\"button2 end\"></div>"];
		}
		
		
		//[NSString stringWithString:@"<div class=\"button end\" ontouchstart=\"$(this).addClass(\\'hover\\')\" ontouchend=\"$(this).removeClass(\\'hover\\')\" ><a href=\"oijlkajsdoihjlkjasdoauto://end\">end</a></div>"];
		
		jsString = [jsString stringByAppendingString:
		 [NSString stringWithFormat:@"$('#endofpage').before('\
		  <div id=\"toolbarpage\">\
		  %@\
		  %@\
		  <a href=\"oijlkajsdoihjlkjasdoauto://choose\">%d/%d</a>\
		  %@\
		  %@\
		  <div>\
		  ');", buttonBegin, buttonPrevious, [self pageNumber], [self lastPageNumber], buttonNext, buttonEnd]
		 ];
	}
	
	
	//NSLog(@"stringFlagTopic %@", self.stringFlagTopic);

	jsString = [jsString stringByAppendingString:[NSString stringWithFormat:@"window.location.hash='%@';", self.stringFlagTopic]];

	
	[webView stringByEvaluatingJavaScriptFromString:jsString];
	//NSLog(@"? webViewDidFinishLoad JS");
	
	
	NSDate *nowT = [NSDate date]; // Create a current date
 	NSLog(@"TOTAL Time elapsed    : %f", [nowT timeIntervalSinceDate:self.firstDate]);	

}
//NSSelectorFromString([[[self arrayAction] objectAtIndex:curPostID] objectForKey:@"code"])
- (BOOL) canPerformAction:(SEL)selector withSender:(id) sender {

	for (id tmpAction in self.arrayAction) {
		if (selector == NSSelectorFromString([tmpAction objectForKey:@"code"])) {
			return YES;
		}
	}
	

	
	return NO;
}
	 
- (BOOL) canBecomeFirstResponder {
	//NSLog(@"canBecomeFirstResponder");
	
    return YES;
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)aRequest navigationType:(UIWebViewNavigationType)navigationType {
	//NSLog(@"expected:%d, got:%d | url:%@", UIWebViewNavigationTypeLinkClicked, navigationType, [aRequest.URL absoluteString]);
	
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		if ([[aRequest.URL scheme] isEqualToString:@"oijlkajsdoihjlkjasdoauto"]) {
			[self goToPage:[[aRequest.URL absoluteString] lastPathComponent]];
			return NO;
		}
		else {
			NSURL *url = aRequest.URL;
			NSString *urlString = url.absoluteString;
			
			[[HFRplusAppDelegate sharedAppDelegate] openURL:urlString];
			return NO;
		}

	}
	else if (navigationType == UIWebViewNavigationTypeOther) {
		if ([[aRequest.URL scheme] isEqualToString:@"oijlkajsdoihjlkjasdodetails"]) {
			[self didSelectMessage:[[[aRequest.URL absoluteString] lastPathComponent] intValue]];
			return NO;
		}
		else if ([[aRequest.URL scheme] isEqualToString:@"oijlkajsdoihjlkjasdorefresh"]) {
			[self searchNewMessages];
			return NO;
		}
		else if ([[aRequest.URL scheme] isEqualToString:@"oijlkajsdoihjlkjasdopopup"]) {
			//NSLog(@"oijlkajsdoihjlkjasdopopup");
			int ypos = [[[[aRequest.URL absoluteString] pathComponents] objectAtIndex:1] intValue];
			int curMsg = [[[[aRequest.URL absoluteString] pathComponents] objectAtIndex:2] intValue];
			//NSLog(@"%d %d", ypos, curMsg);

			[self performSelector:@selector(showMenuCon:andPos:) withObject:[NSNumber numberWithInt:curMsg]  withObject:[NSNumber numberWithInt:ypos]];
			return NO;
		}		
		else if ([[aRequest.URL scheme] isEqualToString:@"oijlkajsdoihjlkjasdoimbrows"]) {
			NSString *regularExpressionString = @"oijlkajsdoihjlkjasdoimbrows://[^/]+/(.*)";

			/*
			NSLog(@"v1 %@", [[[NSString alloc] initWithData:[NSData dataFromBase64String:[[aRequest.URL absoluteString] lastPathComponent]] encoding:NSASCIIStringEncoding] autorelease]);
			
			
			NSLog(@"v2 %@", [[[NSString alloc] initWithData:[NSData dataFromBase64String:
				  [[[aRequest.URL absoluteString] stringByMatching:regularExpressionString capture:1L] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
															 ] encoding:NSASCIIStringEncoding] autorelease]);
			*/
			NSString *imgUrl = [[NSString alloc] initWithData:[NSData dataFromBase64String:
											 [[[aRequest.URL absoluteString] stringByMatching:regularExpressionString capture:1L] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
																] encoding:NSASCIIStringEncoding];
			
			[self didSelectImage:[[[[aRequest.URL absoluteString] pathComponents] objectAtIndex:1] intValue] withUrl:imgUrl];
			[imgUrl release];
			return NO;
		}		
	}

	return YES;
}

-(void) showMenuCon:(NSNumber *)curMsgN andPos:(NSNumber *)posN {
	
	[self.arrayAction removeAllObjects];
	
	int curMsg = [curMsgN intValue];
	int ypos = [posN intValue];
	
	

	
	
	if([[arrayData objectAtIndex:curMsg] urlEdit]){
		//NSLog(@"urlEdit");
		[self.arrayAction addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Editer", @"EditMessage", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];
		
		if (self.navigationItem.rightBarButtonItem.enabled) {
			[self.arrayAction addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Répondre", @"QuoteMessage", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];
		}

	}
	else {
		//NSLog(@"profil");
		if (self.navigationItem.rightBarButtonItem.enabled) {
			[self.arrayAction addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Répondre", @"QuoteMessage", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];
		}
		//[self.arrayAction addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Profil", @"actionProfil", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];
		
		if([[arrayData objectAtIndex:curMsg] MPUrl]){
			//NSLog(@"MPUrl");
			
			[self.arrayAction addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"MP", @"actionMessage", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];
		}
		

	}

	
	//"Citer ☑"@"Citer ☒"@"Citer ☐"	
	if([[arrayData objectAtIndex:curMsg] quoteJS] && self.navigationItem.rightBarButtonItem.enabled) {
		NSString *components = [[[arrayData objectAtIndex:curMsg] quoteJS] substringFromIndex:7];
		components = [components stringByReplacingOccurrencesOfString:@"); return false;" withString:@""];
		components = [components stringByReplacingOccurrencesOfString:@"'" withString:@""];
		
		NSArray *quoteComponents = [components componentsSeparatedByString:@","];
		
		NSString *nameCookie = [NSString stringWithFormat:@"quotes%@-%@-%@", [quoteComponents objectAtIndex:0], [quoteComponents objectAtIndex:1], [quoteComponents objectAtIndex:2]];
		NSString *quotes = [self LireCookie:nameCookie];
		
		if ([quotes rangeOfString:[NSString stringWithFormat:@"|%@", [quoteComponents objectAtIndex:3]]].location == NSNotFound) {
			[self.arrayAction addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Citer ☐", @"actionCiter", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];	
			
		}
		else {
			[self.arrayAction addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Citer ☑", @"actionCiter", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];	
			
		}
		
	}
	
	if ([self canBeFavorite]) {
		//NSLog(@"isRedFlagged ★");
		[self.arrayAction addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"★", @"actionFavoris", nil] forKeys:[NSArray arrayWithObjects:@"title", @"code", nil]]];
	}
	
	
 			
	
	
	self.curPostID = curMsg;
	/*
	UIActionSheet *styleAlert = [[UIActionSheet alloc] init];
	for (id tmpAction in self.arrayAction) {
		[styleAlert addButtonWithTitle:[tmpAction valueForKey:@"title"]];
	}	
	
	[styleAlert addButtonWithTitle:@"Annuler"];
	
	styleAlert.cancelButtonIndex = self.arrayAction.count;
	styleAlert.delegate = self;
	
	styleAlert.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	[styleAlert showInView:[[[HFRplusAppDelegate sharedAppDelegate] rootController] view]];
	//[styleAlert showFromTabBar:[[[HFRplusAppDelegate sharedAppDelegate] rootController] tabBar]];
	[styleAlert release];
	
	*/
	
	UIMenuController *menuController = [UIMenuController sharedMenuController];
	//[menuController setMenuVisible:YES animated:YES];
	
	NSMutableArray *menuAction = [[NSMutableArray alloc] init];
	
	for (id tmpAction in self.arrayAction) {
		//NSLog(@"%@", [tmpAction objectForKey:@"code"]);
		
		UIMenuItem *tmpMenuItem = [[UIMenuItem alloc] initWithTitle:[tmpAction valueForKey:@"title"] action:NSSelectorFromString([tmpAction objectForKey:@"code"])];
		[menuAction addObject:tmpMenuItem];
	}	
	[menuController setMenuItems:menuAction];
	[menuAction release];
	//NSLog(@"menuAction %d", menuAction.count);
	
	//NSLog(@"ypos %d", ypos);
	
	if (ypos < 40) {

		ypos +=34;
		[menuController setArrowDirection:UIMenuControllerArrowUp];
	}
	else {
		[menuController setArrowDirection:UIMenuControllerArrowDown];
	}
	//NSLog(@"oijlkajsdoihjlkjasdopopup 0");
	
	//CGRect myFrame = [[self.view superview] frame];
	//myFrame.size.width-20
	//NSLog(@"%f", myFrame.size.width);
	
	CGRect selectionRect = CGRectMake(38, ypos, 0, 0);
	
	
	[self.view setNeedsDisplayInRect:selectionRect];
	[menuController setTargetRect:selectionRect inView:self.view];
	//[menuController setMenuVisible:YES animated:YES];
	
	//[menuController setTargetRect:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f) inView:self.view];
	
	[menuController setMenuVisible:YES animated:YES];
	//[menuController setMenuVisible:YES];
	//[menuController setMenuVisible:NO];
	
	//NSLog(@"oijlkajsdoihjlkjasdopopup");	
}

- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
	if (buttonIndex < [self.arrayAction count]) {
		//NSLog(@"clickedButtonAtIndex %d %d", buttonIndex, curPostID);
		
		[self performSelector:NSSelectorFromString([[self.arrayAction objectAtIndex:buttonIndex] objectForKey:@"code"]) withObject:[NSNumber numberWithInt:curPostID]];
	}
	
}

#pragma mark -
#pragma mark sharedMenuController management


-(void)actionFavoris:(NSNumber *)curMsgN {
	int curMsg = [curMsgN intValue];

	//NSLog(@"actionFavoris %@", [[arrayData objectAtIndex:curMsg] addFlagUrl]);
	
	ASIHTTPRequest  *aRequest =  
	[[[ASIHTTPRequest  alloc]  initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kForumURL, [[arrayData objectAtIndex:curMsg] addFlagUrl]]]] autorelease];
	[aRequest startSynchronous];
	
	if (request) {
		
		if ([aRequest error]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hmmm..." message:[[request error] localizedDescription]
														   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];	
			[alert release];
			
			//[responseView setText:[[request error] localizedDescription]];
		} else if ([aRequest responseString]) {
			NSString *responseString = [aRequest responseString];
			responseString = [responseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			responseString = [responseString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
			
			NSString *regExMsg = @".*<div class=\"hop\">([^<]+)</div>.*";
			NSPredicate *regExErrorPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regExMsg];
			BOOL isRegExMsg = [regExErrorPredicate evaluateWithObject:responseString];
			
			if (isRegExMsg) {
				//KO
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[responseString stringByMatching:regExMsg capture:1L]
															   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];	
				[alert release];
			}
		}
	}	
	
	
}
-(void)actionProfil:(NSNumber *)curMsgN {
	//NSLog(@"actionProfil");
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Minute papillon !"
												   delegate:self cancelButtonTitle:@"OK OK..." otherButtonTitles: nil];
	[alert show];	
	[alert release];
	
}
-(void)actionMessage:(NSNumber *)curMsgN {
	if (self.isAnimating) {
		return;
	}
	
	int curMsg = [curMsgN intValue];
	
	//NSLog(@"actionMessage %d = %@", curMsg, curMsgN);
	//[[HFRplusAppDelegate sharedAppDelegate] openURL:[NSString stringWithFormat:@"http://forum.hardware.fr%@", forumNewTopicUrl]];
	
	NewMessageViewController *editMessageViewController = [[NewMessageViewController alloc]
														   initWithNibName:@"AddMessageViewController" bundle:nil];
	editMessageViewController.delegate = self;
	[editMessageViewController setUrlQuote:[NSString stringWithFormat:@"http://forum.hardware.fr%@", [[arrayData objectAtIndex:curMsg] MPUrl]]];
	editMessageViewController.title = @"Nouv. Message";
	// Create the navigation controller and present it modally.
	UINavigationController *navigationController = [[UINavigationController alloc]
													initWithRootViewController:editMessageViewController];
	[self presentModalViewController:navigationController animated:YES];
	
	// The navigation controller is now owned by the current view controller
	// and the root view controller is owned by the navigation controller,
	// so both objects should be released to prevent over-retention.
	[navigationController release];
	[editMessageViewController release];
}

-(void) EcrireCookie:(NSString *)nom withVal:(NSString *)valeur {
	//NSLog(@"EcrireCookie");
	
	NSMutableDictionary *	outDict = [NSMutableDictionary dictionaryWithCapacity:5];
	[outDict setObject:nom forKey:NSHTTPCookieName];
	[outDict setObject:valeur forKey:NSHTTPCookieValue];
	[outDict setObject:[[NSDate date] dateByAddingTimeInterval:(60*60)] forKey:NSHTTPCookieExpires];
	[outDict setObject:@".hardware.fr" forKey:NSHTTPCookieDomain];
	[outDict setObject:@"/" forKey:@"Path"];		// This does work.
	
	NSHTTPCookie	*	cookie = [NSHTTPCookie cookieWithProperties:outDict];
	
	NSHTTPCookieStorage *cookShared = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	[cookShared setCookie:cookie];
}

-(NSString *)LireCookie:(NSString *)nom {
	//NSLog(@"LireCookie");
	
	
	NSHTTPCookieStorage *cookShared = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [cookShared cookies];
	
	for (NSHTTPCookie *aCookie in cookies) {
		if ([[aCookie name] isEqualToString:nom]) {
			
			if ([[NSDate date] timeIntervalSinceDate:[aCookie expiresDate]] <= 0) {
				return [aCookie value];
			}
			
		}
		
	}
	
	return @"";
	
}
-(void)  EffaceCookie:(NSString *)nom {
	//NSLog(@"EffaceCookie");
	
	NSHTTPCookieStorage *cookShared = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [cookShared cookies];
	
	for (NSHTTPCookie *aCookie in cookies) {
		if ([[aCookie name] isEqualToString:nom]) {
			[cookShared deleteCookie:aCookie];
		}
		
	}
	
	return;
}


-(void)actionCiter:(NSNumber *)curMsgN {
	//NSLog(@"actionCiter %@", curMsgN);
	
	int curMsg = [curMsgN intValue];
	NSString *components = [[[arrayData objectAtIndex:curMsg] quoteJS] substringFromIndex:7];
	components = [components stringByReplacingOccurrencesOfString:@"); return false;" withString:@""];
	components = [components stringByReplacingOccurrencesOfString:@"'" withString:@""];
	
	NSArray *quoteComponents = [components componentsSeparatedByString:@","];
	
	NSString *nameCookie = [NSString stringWithFormat:@"quotes%@-%@-%@", [quoteComponents objectAtIndex:0], [quoteComponents objectAtIndex:1], [quoteComponents objectAtIndex:2]];
	NSString *quotes = [self LireCookie:nameCookie];
	
	//NSLog(@"quotes APRES LECTURE %@", quotes);
	
	if ([quotes rangeOfString:[NSString stringWithFormat:@"|%@", [quoteComponents objectAtIndex:3]]].location == NSNotFound) {
		quotes = [quotes stringByAppendingString:[NSString stringWithFormat:@"|%@", [quoteComponents objectAtIndex:3]]];
	}
	else {
		quotes = [quotes stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"|%@", [quoteComponents objectAtIndex:3]] withString:@""];
	}
	
	
	if (quotes.length == 0) {
		//
		//NSLog(@"quote vide");
		[self EffaceCookie:nameCookie];
	}
	else
	{
		//NSLog(@"nameCookie %@", nameCookie);
		//NSLog(@"quotes %@", quotes);
		[self EcrireCookie:nameCookie withVal:quotes];
	}
	
	//[self.messageView stringByEvaluatingJavaScriptFromString:@"quoter('hardwarefr','prive',1556872,1962548600);"];
	//NSLog(@"actionCiter %@", [NSDate date]);
	
	//NSHTTPCookieStorage *cookShared = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	//NSArray *cookies = [cookShared cookies];
	
	//for (NSHTTPCookie *aCookie in cookies) {
	//	NSLog(@"%@", aCookie);
	//}
	
	
}

-(void)EditMessage:(NSNumber *)curMsgN {
	int curMsg = [curMsgN intValue];
	
	[self setEditFlagTopic:[[arrayData objectAtIndex:curMsg] postID]];
	[self editMessage:[NSString stringWithFormat:@"http://forum.hardware.fr%@", [[[arrayData objectAtIndex:curMsg] urlEdit] decodeSpanUrlFromString]]];
	
}

-(void)QuoteMessage:(NSNumber *)curMsgN {
	int curMsg = [curMsgN intValue];
	
	[self quoteMessage:[NSString stringWithFormat:@"http://forum.hardware.fr%@", [[[arrayData objectAtIndex:curMsg] urlQuote] decodeSpanUrlFromString]]];
}


-(void)actionFavoris {
	[self actionFavoris:[NSNumber numberWithInt:curPostID]];
	
}
-(void)actionProfil {
	[self actionProfil:[NSNumber numberWithInt:curPostID]];
	
}	
-(void)actionMessage {
	[self actionMessage:[NSNumber numberWithInt:curPostID]];
	
}
-(void)actionCiter {
	[self actionCiter:[NSNumber numberWithInt:curPostID]];
}

-(void)EditMessage
{
	[self EditMessage:[NSNumber numberWithInt:curPostID]];	
}

-(void)QuoteMessage
{
	[self QuoteMessage:[NSNumber numberWithInt:curPostID]];
}

#pragma mark -
#pragma mark Memory management
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	//NSLog(@"viewDidUnload Messages Table View");
	
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	
	self.loadingView = nil;
	
	[self.messagesWebView stopLoading];
	self.messagesWebView.delegate = nil;
	self.messagesWebView = nil;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;	

	[super viewDidUnload];
	
	
}


- (void)dealloc {
	//NSLog(@"dealloc Messages Table View");
	
	[self viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self.queue cancelAllOperations];
	[self.queue release];
	
	[request cancel];
	[request setDelegate:nil];
	self.request = nil;
	
	self.topicAnswerUrl = nil;
	self.topicName = nil;
	
	//[self.arrayData removeAllObjects];
	[self.arrayData release], self.arrayData = nil;
	[self.newArrayData release], self.newArrayData = nil;
	
	if(self.detailViewController) self.detailViewController = nil;
	
	self.swipeLeftRecognizer = nil;
	self.swipeRightRecognizer = nil;
	
	self.stringFlagTopic = nil;
	self.arrayInputData = nil;
		
	self.aToolbar = nil;
	self.editFlagTopic = nil;
	
	self.isFavoritesOrRead = nil;
	self.arrayAction = nil;

    [super dealloc];
	
}

@end

