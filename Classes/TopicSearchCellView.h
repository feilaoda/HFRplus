//
//  TopicCellView.h
//  HFRplus
//
//  Created by FLK on 23/09/10.
//

#import <UIKit/UIKit.h>


@interface TopicSearchCellView : UITableViewCell {
    IBOutlet UILabel *titleLabel;
    IBOutlet UILabel *msgLabel;
    IBOutlet UILabel *timeLabel;
}

@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *msgLabel;
@property (nonatomic, retain) IBOutlet UILabel *timeLabel;


@end
