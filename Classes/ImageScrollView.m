/*
     File: ImageScrollView.m
 Abstract: Centers image within the scroll view and configures image sizing and display.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "ImageScrollView.h"
#import "UIImageViewCustom.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>

@implementation ImageScrollView
@synthesize index, isOK;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self; 
		self.isOK = NO;
		//self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
    }
    return self;
}

- (void)dealloc
{
    [imageView release];
    [super dealloc];
}

#pragma mark -
#pragma mark Override layoutSubviews to center content

- (void)layoutSubviews 
{
	//NSLog(@"layoutSubviews");

    [super layoutSubviews];
    
    // center the image as it becomes smaller than the size of the screen

    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = imageView.frame;
    
    //NSLog(@"1 layoutSubviews BEGIN bounds.size %f - %f", self.bounds.size.width, self.bounds.size.height);

    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;

	//NSLog(@"frameToCenter.size %f - %f", frameToCenter.size.width, frameToCenter.size.height);
	//NSLog(@"frameToCenter.origin %f - %f", frameToCenter.origin.x, frameToCenter.origin.y);    

    //frameToCenter.origin.y = 468.500000;
    //frameToCenter.origin.x = 270.500000;
     
    imageView.frame = frameToCenter;
    
   // NSLog(@"1 layoutSubviews END bounds.size %f - %f", self.bounds.size.width, self.bounds.size.height);    
}


#pragma mark -
#pragma mark UIScrollView delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	//NSLog(@"viewForZoomingInScrollView");
	
    return imageView;
}

#pragma mark -
#pragma mark Configure scrollView to display new image (tiled or not)

- (void)displayImage:(NSString *)image
{
    //NSLog(@"2 displayImage BEGIN bounds.size %f - %f", self.bounds.size.width, self.bounds.size.height);
    
	//NSLog(@"displayImage %@", image);
	image = [image stringByReplacingOccurrencesOfString:@"http://hfr-rehost.net/thumb/" withString:@"http://hfr-rehost.net/preview/"];
    
    // clear the previous imageView
    [imageView removeFromSuperview];
    [imageView release];
    imageView = nil;
    
    // reset our zoomScale to 1.0 before doing any further calculations
    self.zoomScale = 1.0;
	self.isOK = NO;
    // make a new UIImageView for the new image
    //imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photoDefault.png"]];
	
	imageView = [[UIImageViewCustom alloc] initWithFrame:CGRectMake(0, 0, 130, 107)];
	
	//[imageView.layer setBorderColor: [[UIColor blueColor] CGColor]];
	//[imageView.layer setBorderWidth: 1.0];

	imageView.parent = self;
	//imageView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
//[NSURL URLWithString:image]
	[(UIImageViewCustom *)imageView setImageWithURL:[NSURL URLWithString:image]
				 placeholderImage:[UIImage imageNamed:@"photoDefault.png"]];
		
    //imageView.backgroundColor = [UIColor blueColor];
    
    [self addSubview:imageView];
    
	//NSLog(@"imageView.frame.size %f - %f", imageView.frame.size.width, imageView.frame.size.height);
	//NSLog(@"imageView.frame.origin %f - %f", imageView.frame.origin.x, imageView.frame.origin.y);

    //[self configureForImageSize:imageView.frame.size];
    
   // NSLog(@"2 displayImage END bounds.size %f - %f", self.bounds.size.width, self.bounds.size.height);
    
}

- (void)configureForImageSize:(CGSize)imageSize 
{
    //NSLog(@"3 configureForImageSize BEGIN bounds.size %f - %f", self.bounds.size.width, self.bounds.size.height);
    
    CGSize boundsSize = [self bounds].size;
    
	//NSLog(@"imageSize %f - %f", imageSize.width, imageSize.height);
   // NSLog(@"boundsSize %f - %f", boundsSize.width, boundsSize.height);
	
    // set up our content size and min/max zoomscale
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible

	//NSLog(@"xScale - yScale | %f - %f", xScale, yScale);

    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
    CGFloat maxScale = 3;// / [[UIScreen mainScreen] scale];

    // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.) 

	//NSLog(@"B4 %f - %f", maxScale, minScale);

	if (minScale > maxScale) {
        minScale = maxScale;
    }

	if (minScale > 1) {
        minScale = 1;
    }	

	//NSLog(@"AT %f - %f", maxScale, minScale);
	//NSLog(@"contentSize %f - %f", imageSize.width, imageSize.height);
	
    self.contentSize = imageSize;
    self.maximumZoomScale = 3;
    self.minimumZoomScale = minScale;
    self.zoomScale = minScale;  // start out with the content fully visible
    
    //NSLog(@"3 configureForImageSize END bounds.size %f - %f", self.bounds.size.width, self.bounds.size.height);    
}

@end
