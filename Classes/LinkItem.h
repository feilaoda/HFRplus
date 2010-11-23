//
//  Favorite.h
//  HFR+
//
//  Created by Lace on 04/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTMLParser.h"


@interface LinkItem : NSObject {
	NSString *name;
	NSString *url;
	
	NSString *flagUrl;
	NSString *typeFlag;
	
	NSString *lastPostUrl;
	NSString *lastPageUrl;
	
	NSString *postID;

	BOOL viewed;
	BOOL isDel;
	
	int rep;

	NSString *urlQuote;
	NSString *urlEdit;

		
	NSString *dicoHTML;
	HTMLNode *messageNode;

	NSString *imageUrl;
	NSString *imageUI;
	NSString *messageDate;
	NSString *messageAuteur;

	UIView *textViewMsg;
	
	
	NSString *addFlagUrl;
	NSString *quoteJS;
	NSString *MPUrl;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *url;

@property (nonatomic, retain) NSString *flagUrl;
@property (nonatomic, retain) NSString *typeFlag;

@property (nonatomic, retain) NSString *urlQuote;
@property (nonatomic, retain) NSString *urlEdit;

@property (nonatomic, retain) NSString *lastPostUrl;
@property (nonatomic, retain) NSString *lastPageUrl;

@property (nonatomic, retain) NSString *dicoHTML;
@property (nonatomic, retain) HTMLNode *messageNode;

@property (nonatomic, retain) NSString *imageUrl;
@property (nonatomic, retain) NSString *imageUI;

@property (nonatomic, retain) NSString *messageDate;
@property (nonatomic, retain) NSString *messageAuteur;

@property (nonatomic, retain) UIView *textViewMsg;

@property (nonatomic, retain) NSString *postID;

@property (nonatomic, retain) NSString *addFlagUrl;
@property (nonatomic, retain) NSString *quoteJS;
@property (nonatomic, retain) NSString *MPUrl;

@property int rep;
@property BOOL viewed;
@property BOOL isDel;

-(NSString *)toHTML:(int)index;

@end
