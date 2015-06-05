//
//  FSCalendarCell.h
//  Pods
//
//  Created by Wenchao Ding on 12/3/15.
//
//

#import <UIKit/UIKit.h>
#import "FSCalendar.h"
#import "FSCalendarStyle.h"


@interface FSCalendarCellBase : UICollectionViewCell

@property (nonatomic, weak) FSCalendarStyle *style;

@property (copy,   nonatomic) NSString      *title;
@property (copy,   nonatomic) NSString      *subtitle;

@property (copy,   nonatomic) NSDate        *date;
@property (copy,   nonatomic) NSDate        *month;
@property (weak,   nonatomic) NSDate        *currentDate;

@property (assign, nonatomic) BOOL          hasEvent;

- (void)configureCell;

- (BOOL)isPlaceholder;

- (BOOL)isToday;

- (BOOL)isWeekend;

- (void)showAnimation;

- (void)hideAnimation;

@end

@interface FSCalendarCellBase (Subclass)

-(void)configureStyles;

-(UIColor *)colorForCurrentStateInDictionary:(NSDictionary *)dictionary;

@end


@interface FSCalendarCell : FSCalendarCellBase

@property (assign, nonatomic) FSCalendarCellStyle cellStyle;

@property (weak,   nonatomic) UIColor             *eventColor;

@property (weak,   nonatomic) UILabel             *titleLabel;
@property (weak,   nonatomic) UILabel             *subtitleLabel;

@end
