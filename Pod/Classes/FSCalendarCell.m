//
//  FSCalendarCell.m
//  Pods
//
//  Created by Wenchao Ding on 12/3/15.
//
//

#import "FSCalendarCell.h"
#import "FSCalendar.h"
#import "FSCalendarStyle.h"
#import "UIView+FSExtension.h"
#import "NSDate+FSExtension.h"

#define kAnimationDuration 0.15
#define kSizeFactor 1.0


@implementation FSCalendarCellBase

- (void)configureCell
{
    [self configureStyles];
}

-(void)configureStyles
{
    
}

- (void)showAnimation
{
    
}

- (void)hideAnimation
{
    
}

- (BOOL)isPlaceholder
{
    return ![_date fs_isEqualToDateForMonth:_month];
}

- (BOOL)isToday
{
    return [_date fs_isEqualToDateForDay:_currentDate];
}

- (BOOL)isWeekend
{
    return self.date.fs_weekday == 1 || self.date.fs_weekday == 7;
}

- (UIColor *)colorForCurrentStateInDictionary:(NSDictionary *)dictionary
{
    if (self.isSelected) {
        return dictionary[@(FSCalendarCellStateSelected)];
    }
    if (self.isToday) {
        return dictionary[@(FSCalendarCellStateToday)];
    }
    if (self.isPlaceholder) {
        return dictionary[@(FSCalendarCellStatePlaceholder)];
    }
    if (self.isWeekend && [[dictionary allKeys] containsObject:@(FSCalendarCellStateWeekend)]) {
        return dictionary[@(FSCalendarCellStateWeekend)];
    }
    return dictionary[@(FSCalendarCellStateNormal)];
}

@end



@interface FSCalendarCell ()

@property (strong,   nonatomic) CAShapeLayer *backgroundLayer;
@property (strong,   nonatomic) CAShapeLayer *eventLayer;

@end

@implementation FSCalendarCell

#pragma mark - Init and life cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

-(void) initialize
{
    self.cellStyle = FSCalendarCellStyleRectangle;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:15];
    titleLabel.textColor = [UIColor darkTextColor];
    [self.contentView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:10];
    subtitleLabel.textColor = [UIColor lightGrayColor];
    [self.contentView addSubview:subtitleLabel];
    self.subtitleLabel = subtitleLabel;
    
    _backgroundLayer = [CAShapeLayer layer];
    _backgroundLayer.backgroundColor = [UIColor clearColor].CGColor;
    _backgroundLayer.hidden = YES;
    [self.contentView.layer insertSublayer:_backgroundLayer atIndex:0];
    
    _eventLayer = [CAShapeLayer layer];
    _eventLayer.backgroundColor = [UIColor clearColor].CGColor;
    _eventLayer.fillColor = [UIColor cyanColor].CGColor;
    _eventLayer.path = [UIBezierPath bezierPathWithOvalInRect:_eventLayer.bounds].CGPath;
    _eventLayer.hidden = YES;
    [self.contentView.layer addSublayer:_eventLayer];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    CGFloat titleHeight = self.bounds.size.height*kSizeFactor;
    CGFloat diameter = MIN(self.bounds.size.height*kSizeFactor,self.bounds.size.width);
    _backgroundLayer.frame = CGRectMake((self.bounds.size.width-diameter)/2,
                                        (titleHeight-diameter)/2,
                                        diameter,
                                        diameter);
    
    CGFloat eventSize = _backgroundLayer.frame.size.height/6.0;
    _eventLayer.frame = CGRectMake((_backgroundLayer.frame.size.width-eventSize)/2+_backgroundLayer.frame.origin.x,
                                   CGRectGetMaxY(_backgroundLayer.frame)+eventSize*0.2, eventSize*0.8, eventSize*0.8);
    _eventLayer.path = [UIBezierPath bezierPathWithOvalInRect:_eventLayer.bounds].CGPath;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [CATransaction setDisableActions:YES];
}

#pragma mark - Public

- (void)showAnimation
{
    _backgroundLayer.hidden = NO;
    _backgroundLayer.path = [UIBezierPath bezierPathWithOvalInRect:_backgroundLayer.bounds].CGPath;
    _backgroundLayer.fillColor = [self colorForCurrentStateInDictionary:self.style.backgroundColors].CGColor;
    CAAnimationGroup *group = [CAAnimationGroup animation];
    CABasicAnimation *zoomOut = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    zoomOut.fromValue = @0.3;
    zoomOut.toValue = @1.2;
    zoomOut.duration = kAnimationDuration/4*3;
    CABasicAnimation *zoomIn = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    zoomIn.fromValue = @1.2;
    zoomIn.toValue = @1.0;
    zoomIn.beginTime = kAnimationDuration/4*3;
    zoomIn.duration = kAnimationDuration/4;
    group.duration = kAnimationDuration;
    group.animations = @[zoomOut, zoomIn];
    [_backgroundLayer addAnimation:group forKey:@"bounce"];
    [self configureCell];
}

- (void)hideAnimation
{
    _backgroundLayer.hidden = YES;
    [self configureCell];
}

#pragma mark - Private

- (void)configureCell
{
    [super configureCell];
    
    _titleLabel.text = self.title;
    _subtitleLabel.text = self.subtitle;
    
    CGFloat titleHeight = [_titleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.titleLabel.font}].height;
    if (_subtitleLabel.text)
    {
        _subtitleLabel.hidden = NO;
        CGFloat subtitleHeight = [_subtitleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.subtitleLabel.font}].height;
        CGFloat height = titleHeight + subtitleHeight;
        _titleLabel.frame = CGRectMake(0,
                                       (self.contentView.fs_height*5.0/6.0-height)*0.5,
                                       self.fs_width,
                                       titleHeight);
        
        _subtitleLabel.frame = CGRectMake(0,
                                          _titleLabel.fs_bottom - (_titleLabel.fs_height-_titleLabel.font.pointSize),
                                          self.fs_width,
                                          subtitleHeight);
    } else {
        _titleLabel.frame = CGRectMake(0, 0, self.fs_width, floor(self.contentView.fs_height*5.0/6.0));
        _subtitleLabel.hidden = YES;
    }
    
    _backgroundLayer.hidden = NO;//!self.selected && !self.isToday;
    _backgroundLayer.path = _cellStyle == FSCalendarCellStyleCircle ?
    
    [UIBezierPath bezierPathWithOvalInRect:_backgroundLayer.bounds].CGPath :
    [UIBezierPath bezierPathWithRect:_backgroundLayer.bounds].CGPath;
    
    _eventLayer.fillColor = _eventColor.CGColor;
    _eventLayer.hidden = !self.hasEvent;
}

- (void)configureStyles
{
    self.eventColor = self.style.eventColor;
    self.titleLabel.font = self.style.titleFont;
    self.subtitleLabel.font = self.style.subtitleFont;
    
    self.titleLabel.textColor = [self colorForCurrentStateInDictionary:self.style.titleColors];
    self.subtitleLabel.textColor = [self colorForCurrentStateInDictionary:self.style.subtitleColors];
    self.backgroundLayer.fillColor = [self colorForCurrentStateInDictionary:self.style.backgroundColors].CGColor;
}


@end
