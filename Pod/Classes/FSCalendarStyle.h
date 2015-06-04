//
//  FSCalendarStyle.h
//  Pods
//
//  Created by Mateusz Malczak on 04/06/15.
//
//

#import <Foundation/Foundation.h>
#import "FSCalendar.h"

@interface FSCalendarStyle : NSObject

@property (assign, nonatomic) IBInspectable CGFloat              minDissolvedAlpha UI_APPEARANCE_SELECTOR;

@property (strong, nonatomic) UIFont   *titleFont                UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIFont   *subtitleFont             UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIFont   *weekdayFont              UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor  *eventColor               UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor  *weekdayTextColor         UI_APPEARANCE_SELECTOR;

@property (strong, nonatomic) UIColor  *headerTitleColor         UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) NSString *headerDateFormat         UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIFont   *headerTitleFont          UI_APPEARANCE_SELECTOR;

@property (strong, nonatomic) UIColor  *titleDefaultColor        UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor  *titleSelectionColor      UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor  *titleTodayColor          UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor  *titlePlaceholderColor    UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor  *titleWeekendColor        UI_APPEARANCE_SELECTOR;

@property (strong, nonatomic) UIColor  *subtitleDefaultColor     UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor  *subtitleSelectionColor   UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor  *subtitleTodayColor       UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor  *subtitlePlaceholderColor UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor  *subtitleWeekendColor     UI_APPEARANCE_SELECTOR;

@property (strong, nonatomic) UIColor  *selectionColor           UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor  *todayColor               UI_APPEARANCE_SELECTOR;


@property (strong, nonatomic) NSMutableDictionary *backgroundColors;
@property (strong, nonatomic) NSMutableDictionary *titleColors;
@property (strong, nonatomic) NSMutableDictionary *subtitleColors;


@end
