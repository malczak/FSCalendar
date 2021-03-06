//
//  FScalendar.m
//  Pods
//
//  Created by Wenchao Ding on 29/1/15.
//
//

#import "FSCalendar.h"
#import "FSCalendarHeader.h"
#import "UIView+FSExtension.h"
#import "NSDate+FSExtension.h"
#import "NSCalendar+FSExtension.h"
#import "FSCalendarCell.h"

#define kWeekHeight roundf(self.fs_height/9)

@interface FSCalendar (DataSourceAndDelegate)

- (BOOL)hasEventForDate:(NSDate *)date;
- (NSString *)subtitleForDate:(NSDate *)date;

- (BOOL)shouldSelectDate:(NSDate *)date;
- (void)didSelectDate:(NSDate *)date;
- (void)currentMonthDidChange;

@end

@interface FSCalendar ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) NSMutableArray             *weekdays;

@property (weak,   nonatomic) CALayer                    *topBorderLayer;
@property (weak,   nonatomic) CALayer                    *bottomBorderLayer;
@property (weak,   nonatomic) UICollectionView           *collectionView;
@property (weak,   nonatomic) UICollectionViewFlowLayout *collectionViewFlowLayout;

@property (assign, nonatomic) BOOL                       supressEvent;

- (void)adjustTitleIfNecessary;

- (NSDate *)dateForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForDate:(NSDate *)date;

- (void)scrollToDate:(NSDate *)date;
- (void)scrollToDate:(NSDate *)date animate:(BOOL)animate;

- (void)setSelectedDate:(NSDate *)selectedDate animate:(BOOL)animate;

@end

@implementation FSCalendar

@synthesize flow = _flow, firstWeekday = _firstWeekday, style = _style;

#pragma mark - Life Cycle && Initialize

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    NSArray *weekSymbols = [[NSCalendar fs_sharedCalendar] shortStandaloneWeekdaySymbols];
    _weekdays = [NSMutableArray arrayWithCapacity:weekSymbols.count];
    for (int i = 0; i < weekSymbols.count; i++) {
        UILabel *weekdayLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        weekdayLabel.text = weekSymbols[i];
        weekdayLabel.textAlignment = NSTextAlignmentCenter;
        [_weekdays addObject:weekdayLabel];
        [self addSubview:weekdayLabel];
    }
    
    _flow         = FSCalendarFlowHorizontal;
    _firstWeekday = [[NSCalendar fs_sharedCalendar] firstWeekday];
    
    UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewFlowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    collectionViewFlowLayout.minimumInteritemSpacing = 0;
    collectionViewFlowLayout.minimumLineSpacing = 0;
    self.collectionViewFlowLayout = collectionViewFlowLayout;
    
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                                          collectionViewLayout:collectionViewFlowLayout];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.bounces = YES;
    collectionView.pagingEnabled = YES;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.delaysContentTouches = NO;
    collectionView.canCancelContentTouches = YES;
    [self addSubview:collectionView];
    self.collectionView = collectionView;
    
    [self registerCell:[FSCalendarCell class]];
    
    _currentDate = [NSDate date];
    _currentMonth = [_currentDate copy];
    _autoAdjustTitleSize = YES;
    
    CALayer *topBorderLayer = [CALayer layer];
    topBorderLayer.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2].CGColor;
    [self.layer addSublayer:topBorderLayer];
    self.topBorderLayer = topBorderLayer;
    
    CALayer *bottomBorderLayer = [CALayer layer];
    bottomBorderLayer.backgroundColor = _topBorderLayer.backgroundColor;
    [self.layer addSublayer:bottomBorderLayer];
    self.bottomBorderLayer = bottomBorderLayer;
    
    self.minimumDate = [NSDate fs_dateWithYear:1970 month:1 day:1];
    self.maximumDate = [NSDate fs_dateWithYear:2099 month:12 day:31];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollToDate:_currentMonth];
    });
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    _supressEvent = YES;
    CGFloat padding = self.fs_height * 0.01;
    _collectionView.frame = CGRectMake(0, kWeekHeight, self.fs_width, self.fs_height-kWeekHeight);
    _collectionView.contentInset = UIEdgeInsetsZero;
    _collectionViewFlowLayout.itemSize = CGSizeMake(
                                                    _collectionView.fs_width/7-(_flow == FSCalendarFlowVertical)*0.1,
                                                    (_collectionView.fs_height-padding*2)/6
                                                    );
    _collectionViewFlowLayout.sectionInset = UIEdgeInsetsMake(padding, 0, padding, 0);
    
    CGFloat width = self.fs_width/_weekdays.count;
    CGFloat height = kWeekHeight;
    [_weekdays enumerateObjectsUsingBlock:^(UILabel *weekdayLabel, NSUInteger idx, BOOL *stop) {
        NSUInteger absoluteIndex = ((idx-(_firstWeekday-1))+7)%7;
        weekdayLabel.frame = CGRectMake(absoluteIndex*weekdayLabel.fs_width,
                                        0,
                                        width,
                                        height);
    }];
    
    [self adjustTitleIfNecessary];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    if (layer == self.layer) {
        _topBorderLayer.frame = CGRectMake(0, -1, self.fs_width, 1);
        _bottomBorderLayer.frame = CGRectMake(0, self.fs_height, self.fs_width, 1);
    }
}

#pragma mark - UICollectionView dataSource/delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [_maximumDate fs_monthsFrom:_minimumDate] + 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 42;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *date = [self dateForIndexPath:indexPath];

    FSCalendarCellBase *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.style = self.style;
    cell.month = [self.minimumDate fs_dateByAddingMonths:indexPath.section];
    cell.currentDate = self.currentDate;
    cell.date = date;
    cell.title = [NSString stringWithFormat:@"%@",@(date.fs_day)];
    cell.subtitle = [self subtitleForDate:date];
    cell.hasEvent = [self hasEventForDate:date];    
    [cell configureCell];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FSCalendarCellBase *cell = (FSCalendarCellBase *)[collectionView cellForItemAtIndexPath:indexPath];
    if (cell.isPlaceholder) {
        [self setSelectedDate:cell.date animate:YES];
    } else {
        [cell showAnimation];
        _selectedDate = [self dateForIndexPath:indexPath];
        [self didSelectDate:_selectedDate];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FSCalendarCellBase *cell = (FSCalendarCellBase *)[collectionView cellForItemAtIndexPath:indexPath];
    return [self shouldSelectDate:cell.date] && ![[collectionView indexPathsForSelectedItems] containsObject:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FSCalendarCellBase *cell = (FSCalendarCellBase *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell hideAnimation];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [_collectionViewFlowLayout invalidateLayout];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_supressEvent) {
        _supressEvent = NO;
        return;
    }
    CGFloat scrollOffset = MAX(scrollView.contentOffset.x/scrollView.fs_width,
                               scrollView.contentOffset.y/scrollView.fs_height);
    NSDate *currentMonth = [_minimumDate fs_dateByAddingMonths:round(scrollOffset)];
    if (![_currentMonth fs_isEqualToDateForMonth:currentMonth]) {
        _currentMonth = [currentMonth copy];
        [self currentMonthDidChange];
    }
    _header.scrollOffset = scrollOffset;
}

#pragma mark - Setter & Getter

- (void)setMinimumDate:(NSDate *)minimumDate
{
    _minimumDate = [minimumDate copy];
    [self reloadData];
}

- (void)setMaximumDate:(NSDate *)maximumDate
{
    _maximumDate = [maximumDate copy];
    [self reloadData];
}

- (void)setDataSource:(id<FSCalendarDataSource>)dataSource
{
    _dataSource = dataSource;
    [self reloadData];
}

- (void)setFlow:(FSCalendarFlow)flow
{
    if (self.flow != flow) {
        _flow = flow;
        NSIndexPath *newIndexPath;

        if (_collectionView.indexPathsForSelectedItems && _collectionView.indexPathsForSelectedItems.count) {
            NSIndexPath *indexPath = _collectionView.indexPathsForSelectedItems.lastObject;
            if (flow == FSCalendarFlowVertical) {
                NSInteger index  = indexPath.item;
                NSInteger row    = index % 6;
                NSInteger column = index / 6;
                newIndexPath = [NSIndexPath indexPathForRow:column+row*7
                                                               inSection:indexPath.section];
            } else if (flow == FSCalendarFlowHorizontal) {
                NSInteger index  = indexPath.item;
                NSInteger row    = index / 7;
                NSInteger column = index % 7;
                newIndexPath = [NSIndexPath indexPathForRow:row+column*6
                                                               inSection:indexPath.section];
            }
        }
        _collectionViewFlowLayout.scrollDirection = (UICollectionViewScrollDirection)flow;
        [self setNeedsLayout];
        [self reloadData:newIndexPath];
    }
}

- (FSCalendarFlow)flow
{
    return (FSCalendarFlow)_collectionViewFlowLayout.scrollDirection;
}

- (void)setFirstWeekday:(NSUInteger)firstWeekday
{
    if (_firstWeekday != firstWeekday) {
        _firstWeekday = firstWeekday;
        [[NSCalendar fs_sharedCalendar] setFirstWeekday:firstWeekday];
        [self reloadData];
    }
}

- (void)setSelectedDate:(NSDate *)selectedDate
{
    [self setSelectedDate:selectedDate animate:NO];
}

- (void)setSelectedDate:(NSDate *)selectedDate animate:(BOOL)animate
{
    NSIndexPath *selectedIndexPath = [self indexPathForDate:selectedDate];
    if (![_selectedDate fs_isEqualToDateForDay:selectedDate] && [self collectionView:_collectionView shouldSelectItemAtIndexPath:selectedIndexPath]) {
        NSIndexPath *currentIndex = [_collectionView indexPathsForSelectedItems].lastObject;
        [_collectionView deselectItemAtIndexPath:currentIndex animated:NO];
        [self collectionView:_collectionView didDeselectItemAtIndexPath:currentIndex];
        [_collectionView selectItemAtIndexPath:selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [self collectionView:_collectionView didSelectItemAtIndexPath:selectedIndexPath];
    }
    if (!_collectionView.tracking && !_collectionView.decelerating && ![_currentMonth fs_isEqualToDateForMonth:_selectedDate]) {
        [self scrollToDate:selectedDate animate:animate];
    }
}


- (void)setCurrentDate:(NSDate *)currentDate
{
    if (![_currentDate fs_isEqualToDateForDay:currentDate]) {
        _currentDate = [currentDate copy];
        _currentMonth = [currentDate copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToDate:_currentDate];
        });
    }
}

- (void)setCurrentMonth:(NSDate *)currentMonth
{
    if (![_currentMonth fs_isEqualToDateForMonth:currentMonth]) {
        _currentMonth = [currentMonth copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToDate:_currentMonth];
            [self currentMonthDidChange];
        });
    }
}

- (void)setHeader:(FSCalendarHeader *)header
{
    if (_header != header) {
        _header = header;
        _header.calendar = self;
        _topBorderLayer.hidden = header != nil;
    }
}

- (void)setHeaderDateFormat:(NSString *)dateFormat
{
    _header.dateFormat = dateFormat;
}

- (NSString *)headerDateFormat
{
    return _header.dateFormat;
}

-(FSCalendarStyle *)style
{
    if(!_style)
    {
        _style = [[FSCalendarStyle alloc] init];
    }
    return _style;
}

-(void)setStyle:(FSCalendarStyle *)style
{
    if(_style != style)
    {
        _style = style;
        [self updateStyles];
    }
}

#pragma mark - Public

- (void) updateStyles
{
    for (UILabel *weekdayLabel in _weekdays)
    {
        weekdayLabel.font = self.style.weekdayFont;
        weekdayLabel.textColor = self.style.weekdayTextColor;
    }

    [self reloadData];
}

- (void)reloadData
{
    NSIndexPath *selectedPath = [_collectionView indexPathsForSelectedItems].lastObject;
    [self reloadData:selectedPath];
}

#pragma mark - Private

- (void) ensureDateInRange
{
    NSCalendar *calendar = [NSCalendar fs_sharedCalendar];
    
    if ( NSOrderedDescending == [calendar compareDate:self.minimumDate
                                               toDate:_currentDate
                                    toUnitGranularity:NSCalendarUnitDay])
    {
        _currentDate = [self.minimumDate copy];
    }
    
    if ( NSOrderedAscending == [calendar compareDate:self.maximumDate
                                              toDate:_currentDate
                                   toUnitGranularity:NSCalendarUnitDay])
    {
        _currentDate = [self.maximumDate copy];
    }
    
    [self reloadData];
}

- (void)scrollToDate:(NSDate *)date
{
    [self scrollToDate:date animate:NO];
}

- (void)scrollToDate:(NSDate *)date animate:(BOOL)animate
{
    NSInteger scrollOffset = [date fs_monthsFrom:_minimumDate];
    _supressEvent = !animate;
    if (self.flow == FSCalendarFlowHorizontal) {
        [_collectionView setContentOffset:CGPointMake(scrollOffset * _collectionView.fs_width, 0) animated:animate];
    } else if (self.flow == FSCalendarFlowVertical) {
        [_collectionView setContentOffset:CGPointMake(0, scrollOffset * _collectionView.fs_height) animated:animate];
    }
    if (_header && !animate) {
        _header.scrollOffset = scrollOffset;
    }
}

- (NSDate *)dateForIndexPath:(NSIndexPath *)indexPath
{
    NSDate *currentMonth = [_minimumDate fs_dateByAddingMonths:indexPath.section];
    NSDate *firstDayOfMonth = [NSDate fs_dateWithYear:currentMonth.fs_year
                                                month:currentMonth.fs_month
                                                  day:1];
    NSInteger numberOfPlaceholdersForPrev = ((firstDayOfMonth.fs_weekday - _firstWeekday) + 7) % 7 ? : 7;
    NSDate *firstDateOfPage = [firstDayOfMonth fs_dateBySubtractingDays:numberOfPlaceholdersForPrev];
    NSDate *date;
    if (self.flow == FSCalendarFlowHorizontal) {
        NSUInteger    rows = indexPath.item % 6;
        NSUInteger columns = indexPath.item / 6;
        date = [firstDateOfPage fs_dateByAddingDays:7 * rows + columns];
    } else {
        date = [firstDateOfPage fs_dateByAddingDays:indexPath.item];
    }
    return date;
}

- (NSIndexPath *)indexPathForDate:(NSDate *)date
{
    NSInteger section = [date fs_monthsFrom:_minimumDate];
    NSDate *firstDayOfMonth = [NSDate fs_dateWithYear:date.fs_year month:date.fs_month day:1];
    NSInteger numberOfPlaceholdersForPrev = ((firstDayOfMonth.fs_weekday - _firstWeekday) + 7) % 7 ? : 7;
    NSDate *firstDateOfPage = [firstDayOfMonth fs_dateBySubtractingDays:numberOfPlaceholdersForPrev];
    NSInteger item = 0;
    if (self.flow == FSCalendarFlowHorizontal) {
        NSInteger vItem = [date fs_daysFrom:firstDateOfPage];
        NSInteger rows = vItem/7;
        NSInteger columns = vItem%7;
        item = columns*6 + rows;
    } else if (self.flow == FSCalendarFlowVertical) {
        item = [date fs_daysFrom:firstDateOfPage];
    }
    return [NSIndexPath indexPathForItem:item inSection:section];
}

- (void)adjustTitleIfNecessary
{
    if (_autoAdjustTitleSize) {
        self.style.titleFont       = [self.style.titleFont fontWithSize:_collectionView.fs_height/3/6];
        self.style.subtitleFont    = [self.style.subtitleFont fontWithSize:_collectionView.fs_height/4.5/6];
        self.style.headerTitleFont = [self.style.headerTitleFont fontWithSize:self.style.titleFont.pointSize+3];
        self.style.weekdayFont     = self.style.titleFont;
        [self reloadData];
    }
}

- (BOOL)shouldSelectDate:(NSDate *)date
{
    if (_delegate && [_delegate respondsToSelector:@selector(calendar:shouldSelectDate:)]) {
        return [_delegate calendar:self shouldSelectDate:date];
    }
    return YES;
}

- (void)didSelectDate:(NSDate *)date
{
    if (_delegate && [_delegate respondsToSelector:@selector(calendar:didSelectDate:)]) {
        [_delegate calendar:self didSelectDate:date];
    }
}

- (void)currentMonthDidChange
{
    if (_delegate && [_delegate respondsToSelector:@selector(calendarCurrentMonthDidChange:)]) {
        [_delegate calendarCurrentMonthDidChange:self];
    }
}

- (NSString *)subtitleForDate:(NSDate *)date
{
    if (_dataSource && [_dataSource respondsToSelector:@selector(calendar:subtitleForDate:)]) {
        return [_dataSource calendar:self subtitleForDate:date];
    }
    return nil;
}

- (BOOL)hasEventForDate:(NSDate *)date
{
    if (_dataSource && [_dataSource respondsToSelector:@selector(calendar:hasEventForDate:)]) {
        return [_dataSource calendar:self hasEventForDate:date];
    }
    return NO;
}

- (void)setAutoAdjustTitleSize:(BOOL)autoAdjustTitleSize
{
    if (_autoAdjustTitleSize != autoAdjustTitleSize) {
        _autoAdjustTitleSize = autoAdjustTitleSize;
        [self reloadData];
    }
}

- (void)reloadData:(NSIndexPath *)selection
{
    [_collectionView reloadData];
    [_collectionView selectItemAtIndexPath:selection animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    
    _header.scrollDirection = self.collectionViewFlowLayout.scrollDirection;
    _header.titleColor = self.style.headerTitleColor;
    _header.titleFont = self.style.headerTitleFont;
    [_header reloadData];
    
    CGFloat width = self.fs_width/_weekdays.count;
    CGFloat height = kWeekHeight;
    [_weekdays enumerateObjectsUsingBlock:^(UILabel *weekdayLabel, NSUInteger idx, BOOL *stop) {
        NSUInteger absoluteIndex = ((idx-(_firstWeekday-1))+7)%7;
        weekdayLabel.frame = CGRectMake(absoluteIndex*weekdayLabel.fs_width,
                                        0,
                                        width,
                                        height);
    }];
}

- (void)registerCell:(Class) cellClass
{
    [self.collectionView registerClass:cellClass
            forCellWithReuseIdentifier:@"cell"];
}

@end

