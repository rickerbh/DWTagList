//
//  DWTagList.m
//
//  Created by Dominic Wroblewski on 07/07/2012.
//  Copyright (c) 2012 Terracoding LTD. All rights reserved.
//

#import "DWTagList.h"
#import <QuartzCore/QuartzCore.h>

#define CORNER_RADIUS 10.0f
#define LABEL_MARGIN_DEFAULT 7.0f
#define BOTTOM_MARGIN_DEFAULT 7.0f
#define FONT_SIZE_DEFAULT 13.0f
#define HORIZONTAL_PADDING_DEFAULT 7.0f
#define VERTICAL_PADDING_DEFAULT 5.0f
#define BACKGROUND_COLOR [UIColor clearColor]
#define TEXT_COLOR [UIColor darkGrayColor]
#define TEXT_SHADOW_COLOR [UIColor clearColor]
#define TEXT_SHADOW_OFFSET CGSizeMake(0.0f, 0.0f)
#define BORDER_COLOR [UIColor lightGrayColor]
#define BORDER_WIDTH 1.0f
#define HIGHLIGHTED_BACKGROUND_COLOR [UIColor colorWithRed:0.40 green:0.80 blue:1.00 alpha:0.5]
#define DEFAULT_AUTOMATIC_RESIZE NO
#define SELECTED_BACKGROUND_COLOR [UIColor colorWithRed:(51.0/255.0) green:(170.0/255.0) blue:(220.0/255.0) alpha:1.00]
#define SELECTED_BORDER_COLOR [UIColor colorWithRed:(51.0/255.0) green:(170.0/255.0) blue:(220.0/255.0) alpha:1.00]
#define DEFAULT_SHOW_TAG_MENU NO

@interface DWTagList () <DWTagViewDelegate>

@property(nonatomic, strong) NSMutableSet *selectedTags;
@property(nonatomic, strong) NSMutableDictionary *tagAppearanceLookup;

@property(nonatomic, strong) UIColor *selectedBorderColor;
@property(nonatomic, strong) UIColor *selectedBGColor;

@end

@implementation DWTagList

@synthesize view, textArray, automaticResize;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:view];
        [self setClipsToBounds:YES];
        self.automaticResize = DEFAULT_AUTOMATIC_RESIZE;
        self.highlightedBackgroundColor = HIGHLIGHTED_BACKGROUND_COLOR;
        self.font = [UIFont systemFontOfSize:FONT_SIZE_DEFAULT];
        self.labelMargin = LABEL_MARGIN_DEFAULT;
        self.bottomMargin = BOTTOM_MARGIN_DEFAULT;
        self.horizontalPadding = HORIZONTAL_PADDING_DEFAULT;
        self.verticalPadding = VERTICAL_PADDING_DEFAULT;
        self.cornerRadius = CORNER_RADIUS;
        self.borderColor = BORDER_COLOR;
        self.borderWidth = BORDER_WIDTH;
        self.textColor = TEXT_COLOR;
        self.textShadowColor = TEXT_SHADOW_COLOR;
        self.textShadowOffset = TEXT_SHADOW_OFFSET;
        self.selectedBGColor = SELECTED_BACKGROUND_COLOR;
        self.selectedBorderColor = SELECTED_BORDER_COLOR;
        
        self.tagAppearanceLookup = [[NSMutableDictionary alloc] init];
        self.showTagMenu = DEFAULT_SHOW_TAG_MENU;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addSubview:view];
        [self setClipsToBounds:YES];
        self.highlightedBackgroundColor = HIGHLIGHTED_BACKGROUND_COLOR;
        self.font = [UIFont systemFontOfSize:FONT_SIZE_DEFAULT];
        self.labelMargin = LABEL_MARGIN_DEFAULT;
        self.bottomMargin = BOTTOM_MARGIN_DEFAULT;
        self.horizontalPadding = HORIZONTAL_PADDING_DEFAULT;
        self.verticalPadding = VERTICAL_PADDING_DEFAULT;
        self.cornerRadius = CORNER_RADIUS;
        self.borderColor = BORDER_COLOR;
        self.borderWidth = BORDER_WIDTH;
        self.textColor = TEXT_COLOR;
        self.textShadowColor = TEXT_SHADOW_COLOR;
        self.textShadowOffset = TEXT_SHADOW_OFFSET;
        self.selectedBGColor = SELECTED_BACKGROUND_COLOR;
        self.selectedBorderColor = SELECTED_BORDER_COLOR;

        self.tagAppearanceLookup = [[NSMutableDictionary alloc] init];
        self.showTagMenu = DEFAULT_SHOW_TAG_MENU;
    }
    return self;
}

- (void)setTags:(NSArray *)array
{
    textArray = [[NSArray alloc] initWithArray:array];
    sizeFit = CGSizeZero;
    [self display];
}

- (void)setTags:(NSArray *)array selectedTags:(NSArray*) selectedTags
{
    self.selectedTags = [NSMutableSet setWithArray:selectedTags];
    [self setTags:array];
}

- (void)setTagBackgroundColor:(UIColor *)color
{
    lblBackgroundColor = color;
    [self display];
}

- (void)setTagHighlightColor:(UIColor *)color
{
    self.highlightedBackgroundColor = color;
    [self display];
}

- (void)setTagAlignment:(DWTagAlignment)tagAlignment
{
    if (_tagAlignment != tagAlignment) {
        _tagAlignment = tagAlignment;
        [self display];
    }
}

- (void)setViewOnly:(BOOL)viewOnly
{
    if (_viewOnly != viewOnly) {
        _viewOnly = viewOnly;
        [self display];
    }
}

- (void)setFont:(UIFont *)font
{
    if (font != _font) {
        _font = font;
        [self display];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self display];
}

- (void)display
{
    NSMutableArray *tagViews = [NSMutableArray array];
    for (UIView *subview in [self subviews]) {
        if ([subview isKindOfClass:[DWTagView class]]) {
            DWTagView *tagView = (DWTagView*)subview;
            for (UIGestureRecognizer *gesture in [subview gestureRecognizers]) {
                [subview removeGestureRecognizer:gesture];
            }

            [tagView.button removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];

            [tagViews addObject:subview];
        }
        [subview removeFromSuperview];
      [self.tagAppearanceLookup removeAllObjects];
    }

    CGRect previousFrame = CGRectZero;
    BOOL gotPreviousFrame = NO;

    NSInteger tag = 0;

    NSMutableArray *allTagViewsByLine = [[NSMutableArray alloc] init];

    NSInteger currentLine = 0;
    for (id text in textArray) {
        DWTagView *tagView;
        if (tagViews.count > 0) {
            tagView = [tagViews lastObject];
            [tagViews removeLastObject];
        }
        else {
            tagView = [[DWTagView alloc] init];
        }
        
        DWTagAppearance *appearance = [self.tagAppearanceLookup objectForKey:text];
        
        if (!appearance)
        {
            BOOL selected = [self.selectedTags containsObject:text];
            
            appearance = [self createTagAppearance:selected];
            
            [self.tagAppearanceLookup setObject:appearance forKey:text];
        }
        
        [tagView updateWithString:text
                             font:self.font
               constrainedToWidth:self.frame.size.width - (self.horizontalPadding * 2)
                          padding:CGSizeMake(self.horizontalPadding, self.verticalPadding)
                     minimumWidth:self.minimumWidth
         ];

        if (gotPreviousFrame) {
            CGRect newRect = CGRectZero;
            if (previousFrame.origin.x + previousFrame.size.width + tagView.frame.size.width + self.labelMargin > self.frame.size.width) {
                currentLine++;
                newRect.origin = CGPointMake(0, previousFrame.origin.y + tagView.frame.size.height + self.bottomMargin);
            } else {
                newRect.origin = CGPointMake(previousFrame.origin.x + previousFrame.size.width + self.labelMargin, previousFrame.origin.y);
            }
            newRect.size = tagView.frame.size;
            [tagView setFrame:newRect];
        }

        if (allTagViewsByLine.count == currentLine) {
            [allTagViewsByLine addObject:[[NSMutableArray alloc] init]];
        }
        [allTagViewsByLine[currentLine] addObject:tagView];

        previousFrame = tagView.frame;
        gotPreviousFrame = YES;

        [tagView setBackgroundColor:appearance.backgroundColor];
        [tagView setCornerRadius:self.cornerRadius];
        [tagView setBorderColor:appearance.borderColor.CGColor];
        [tagView setBorderWidth:self.borderWidth];
        [tagView setTextColor:appearance.textColor];
        [tagView setTextShadowColor:appearance.textShadowColor];
        [tagView setTextShadowOffset:self.textShadowOffset];
        [tagView setTag:tag];
        [tagView setDelegate:self];

        tag++;

        [self addSubview:tagView];

        if (!_viewOnly) {
            [tagView.button addTarget:self action:@selector(touchDownInside:) forControlEvents:UIControlEventTouchDown];
            [tagView.button addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
            [tagView.button addTarget:self action:@selector(touchDragExit:) forControlEvents:UIControlEventTouchDragExit];
            [tagView.button addTarget:self action:@selector(touchDragInside:) forControlEvents:UIControlEventTouchDragInside];
        }
    }

    if (_tagAlignment == DWTagAlignmentCenter) {
        for(NSArray *tagViews in allTagViewsByLine) {
            UIView *lastView = (UIView *)tagViews.lastObject;
            CGFloat remainingSpace = self.frame.size.width - (lastView.frame.origin.x + lastView.frame.size.width);
            for (DWTagView *tagView in tagViews) {
                CGRect newRect = tagView.frame;
                newRect.origin = CGPointMake((NSInteger)(newRect.origin.x + ( remainingSpace / 2 )), newRect.origin.y);
                tagView.frame = newRect;
            }
        }
    }

    sizeFit = CGSizeMake(self.frame.size.width, previousFrame.origin.y + previousFrame.size.height + self.bottomMargin + 1.0f);
    self.contentSize = sizeFit;
    [self invalidateIntrinsicContentSize];

    if (automaticResize) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, sizeFit.width, sizeFit.height);
    }
}

-(DWTagAppearance*) createTagAppearance:(BOOL) selected
{
    DWTagAppearance *appearance = [[DWTagAppearance alloc] init];
    
    if (selected)
    {
        appearance.borderColor = self.selectedBorderColor;
        appearance.textColor = [UIColor whiteColor];
        appearance.textShadowColor = TEXT_SHADOW_COLOR;
        appearance.backgroundColor = self.selectedBGColor;
        appearance.selected = YES;
    }
    else
    {
        appearance.borderColor = BORDER_COLOR;
        appearance.textColor = TEXT_COLOR;
        appearance.textShadowColor = TEXT_SHADOW_COLOR;
        appearance.backgroundColor = BACKGROUND_COLOR;
        appearance.selected = NO;
    }

    return appearance;
}

- (CGSize)fittedSize
{
    return sizeFit;
}

- (CGSize)intrinsicContentSize
{
    if (automaticResize) {
        return CGSizeMake(sizeFit.width, sizeFit.height);
    }
    else {
        return CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
    }
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    [self setContentOffset: CGPointMake(0.0, self.contentSize.height - self.bounds.size.height + self.contentInset.bottom) animated: animated];
}

- (void)touchDownInside:(id)sender
{
    UIButton *button = (UIButton*)sender;
    [[button superview] setBackgroundColor:self.highlightedBackgroundColor];
}

- (void)touchUpInside:(id)sender
{
  UIButton *button = (UIButton*)sender;
  DWTagView *tagView = (DWTagView *)[button superview];
  [tagView setBackgroundColor:[self getBackgroundColor]];

    NSString* tagText = button.accessibilityLabel;
  
    BOOL selected = [self.selectedTags containsObject:tagText];

  if (selected) {
    [self.selectedTags removeObject:tagText];
    if ([self.tagDelegate respondsToSelector:@selector(deselectedTag:tagIndex:)]) {
      [self.tagDelegate deselectedTag:tagText tagIndex:button.tag];
    }
    
    if(self.tagDelegate && [self.tagDelegate respondsToSelector:@selector(deselectedTag:)]) {
      [self.tagDelegate deselectedTag:tagText];
    }
  } else {
    [self.selectedTags addObject:tagText];
    if ([self.tagDelegate respondsToSelector:@selector(selectedTag:tagIndex:)]) {
      [self.tagDelegate selectedTag:tagText tagIndex:button.tag];
    }

    if ([self.tagDelegate respondsToSelector:@selector(selectedTag:)]) {
        [self.tagDelegate selectedTag:tagView.label.text];
    }

    if (self.showTagMenu) {
      UIMenuController *menuController = [UIMenuController sharedMenuController];
      [menuController setTargetRect:button.frame inView:self];
      [menuController setMenuVisible:YES animated:YES];
      [button becomeFirstResponder];
    }
  }
  
    [self toggleTagSelection:tagText];
}

- (void)touchDragExit:(id)sender
{
    UIButton *button = (UIButton*)sender;
    [[button superview] setBackgroundColor:[self getBackgroundColor]];
}

- (void)touchDragInside:(id)sender
{
    UIButton *button = (UIButton*)sender;
    [[button superview] setBackgroundColor:[self getBackgroundColor]];
}

- (UIColor *)getBackgroundColor
{
    if (!lblBackgroundColor) {
        return BACKGROUND_COLOR;
    } else {
        return lblBackgroundColor;
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
    [self display];
}

- (void)setBorderColor:(UIColor*)borderColor
{
    _borderColor = borderColor;
    [self display];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    [self display];
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    [self display];
}

- (void)setTextShadowColor:(UIColor *)textShadowColor
{
    _textShadowColor = textShadowColor;
    [self display];
}

- (void)setTextShadowOffset:(CGSize)textShadowOffset
{
    _textShadowOffset = textShadowOffset;
    [self display];
}

- (void)dealloc
{
    view = nil;
    textArray = nil;
    lblBackgroundColor = nil;
}

- (void) toggleTagSelection:(NSString*) tag
{
    DWTagAppearance *appearance = [self.tagAppearanceLookup objectForKey:tag];
    BOOL selected = appearance.selected;
    
    if (selected)
    {
        appearance.borderColor = BORDER_COLOR;
        appearance.textColor = TEXT_COLOR;
        appearance.textShadowColor = TEXT_SHADOW_COLOR;
        appearance.backgroundColor = BACKGROUND_COLOR;
        appearance.selected = NO;
    }
    else
    {
        appearance.borderColor = self.selectedBorderColor;
        appearance.textColor = [UIColor whiteColor];
        appearance.textShadowColor = TEXT_SHADOW_COLOR;
        appearance.backgroundColor = self.selectedBGColor;
        appearance.selected = YES;
    }

    [self display];
}

#pragma mark - DWTagViewDelegate

- (void)tagViewWantsToBeDeleted:(DWTagView *)tagView {
    NSMutableArray *mTextArray = [self.textArray mutableCopy];
    [mTextArray removeObject:tagView.label.text];
    [self setTags:mTextArray];

    if ([self.tagDelegate respondsToSelector:@selector(tagListTagsChanged:)]) {
        [self.tagDelegate tagListTagsChanged:self];
    }
}

@end

@implementation DWTagAppearance

@end

@implementation DWTagView

- (id)init
{
    self = [super init];
    if (self) {
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        [_label setTextColor:TEXT_COLOR];
        [_label setShadowColor:TEXT_SHADOW_COLOR];
        [_label setShadowOffset:TEXT_SHADOW_OFFSET];
        [_label setBackgroundColor:[UIColor clearColor]];
        [_label setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:_label];

        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [_button setFrame:self.frame];
        [self addSubview:_button];

        [self.layer setMasksToBounds:YES];
        [self.layer setCornerRadius:CORNER_RADIUS];
        [self.layer setBorderColor:BORDER_COLOR.CGColor];
        [self.layer setBorderWidth:BORDER_WIDTH];
    }
    return self;
}

- (void)updateWithString:(id)text font:(UIFont*)font constrainedToWidth:(CGFloat)maxWidth padding:(CGSize)padding minimumWidth:(CGFloat)minimumWidth
{
    CGSize textSize = CGSizeZero;
    BOOL isTextAttributedString = [text isKindOfClass:[NSAttributedString class]];

    if (isTextAttributedString) {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:text];
        [attributedString addAttributes:@{NSFontAttributeName: font} range:NSMakeRange(0, ((NSAttributedString *)text).string.length)];

        textSize = [attributedString boundingRectWithSize:CGSizeMake(maxWidth, 0) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        _label.attributedText = [attributedString copy];
    } else {
        textSize = [text sizeWithFont:font forWidth:maxWidth lineBreakMode:NSLineBreakByTruncatingTail];
        _label.text = text;
    }

    textSize.width = MAX(textSize.width, minimumWidth);
    textSize.height += padding.height*2;

    self.frame = CGRectMake(0, 0, textSize.width+padding.width*2, textSize.height);
    _label.frame = CGRectMake(padding.width, 0, MIN(textSize.width, self.frame.size.width), textSize.height);
    _label.font = font;

    [_button setAccessibilityLabel:self.label.text];
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    [self.layer setCornerRadius:cornerRadius];
}

- (void)setBorderColor:(CGColorRef)borderColor
{
    [self.layer setBorderColor:borderColor];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    [self.layer setBorderWidth:borderWidth];
}

- (void)setLabelText:(NSString*)text
{
    [_label setText:text];
}

- (void)setTextColor:(UIColor *)textColor
{
    [_label setTextColor:textColor];
}

- (void)setTextShadowColor:(UIColor*)textShadowColor
{
    [_label setShadowColor:textShadowColor];
}

- (void)setTextShadowOffset:(CGSize)textShadowOffset
{
    [_label setShadowOffset:textShadowOffset];
}

- (void)dealloc
{
    _label = nil;
    _button = nil;
}

#pragma mark - UIMenuController support

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return (action == @selector(copy:)) || (action == @selector(delete:));
}

- (void)copy:(id)sender
{
    [[UIPasteboard generalPasteboard] setString:self.label.text];
}

- (void)delete:(id)sender
{
    [self.delegate tagViewWantsToBeDeleted:self];
}

@end
