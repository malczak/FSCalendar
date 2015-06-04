//
//  FScalendar.h
//  Pods
//
//  Created by Wenchao Ding on 29/1/15.
//
//

#import <UIKit/UIKit.h>
#import "FSCalendarStyle.h"
#import "FSCalendarHeader.h"

@class FSCalendar;

typedef NS_ENUM(NSInteger, FSCalendarFlow) {
    FSCalendarFlowVertical ,
    FSCalendarFlowHorizontal
};

typedef NS_OPTIONS(NSInteger, FSCalendarCellStyle) {
    FSCalendarCellStyleCircle      = 0,
    FSCalendarCellStyleRectangle   = 1
};

typedef NS_OPTIONS(NSInteger, FSCalendarCellState) {
    FSCalendarCellStateNormal      = 0,
    FSCalendarCellStateSelected    = 1,
    FSCalendarCellStatePlaceholder = 1 << 1,
    FSCalendarCellStateDisabled    = 1 << 2,
    FSCalendarCellStateToday       = 1 << 3,
    FSCalendarCellStateWeekend     = 1 << 4
};

@protocol FSCalendarDelegate <NSObject>

@optional
- (BOOL)calendar:(FSCalendar *)calendar shouldSelectDate:(NSDate *)date;
- (void)calendar:(FSCalendar *)calendar didSelectDate:(NSDate *)date;
- (void)calendarCurrentMonthDidChange:(FSCalendar *)calendar;

@end


@protocol FSCalendarDataSource <NSObject>

@optional

- (NSString *)calendar:(FSCalendar *)calendar subtitleForDate:(NSDate *)date;
- (BOOL)calendar:(FSCalendar *)calendar hasEventForDate:(NSDate *)date;

@end


@interface FSCalendar : UIView

@property (weak,   nonatomic) IBOutlet    FSCalendarHeader     *header;
@property (weak,   nonatomic) IBOutlet id<FSCalendarDelegate>   delegate;
@property (weak,   nonatomic) IBOutlet id<FSCalendarDataSource> dataSource;

@property (strong, nonatomic) FSCalendarStyle *style;

@property (copy,   nonatomic) NSDate *minimumDate;
@property (copy,   nonatomic) NSDate *maximumDate;
@property (copy,   nonatomic) NSDate *currentDate;
@property (copy,   nonatomic) NSDate *selectedDate;
@property (copy,   nonatomic) NSDate *currentMonth;

@property (assign, nonatomic) FSCalendarFlow flow;
@property (assign, nonatomic) NSUInteger firstWeekday;
@property (assign, nonatomic) BOOL autoAdjustTitleSize;

- (void)scrollToDate:(NSDate *)date;

- (void)scrollToDate:(NSDate *)date animate:(BOOL)animate;

- (NSDate *)dateForIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)indexPathForDate:(NSDate *)date;

- (void)reloadData;

@end



