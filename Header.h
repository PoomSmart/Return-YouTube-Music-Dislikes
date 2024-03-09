#import <UIKit/UIKit.h>
#import <YouTubeHeader/GOOAlertView.h>
#import <YouTubeHeader/YTInnerTubeCollectionViewController.h>
#import <YouTubeHeader/YTResponder.h>
#import <YouTubeHeader/YTSettingsSectionController.h>
#import <YouTubeHeader/YTSettingsSectionItem.h>

@interface GOOHeaderViewController : UIViewController
@end

@interface YTBaseInnerTubeViewController : UIViewController <YTResponder>
@end

@interface YTMBaseInnerTubeViewController : YTBaseInnerTubeViewController
@end

@interface YTMInnerTubeCollectionViewController : YTInnerTubeCollectionViewController
@end

@interface YTMSettingsResponseViewController : YTMBaseInnerTubeViewController
- (instancetype)initWithService:(id)service parentResponder:(id <YTResponder>)parentResponder;
- (YTMInnerTubeCollectionViewController *)collectionViewController;
@end

@interface YTMSettingsSectionItem : YTSettingsSectionItem
@property (nonatomic, assign, readwrite, getter=isAsynchronous) BOOL asynchronous;
@end

@interface YTMSettingsSectionController : YTSettingsSectionController <YTResponder>
@property (nonatomic, assign, readwrite) int categoryID;
- (instancetype)initWithTitle:(NSString *)title items:(NSArray <YTMSettingsSectionItem *> *)items parentResponder:(id <YTResponder>)parentResponder;
@end

@interface YTMSettingCollectionSectionController : YTMSettingsSectionController
@end

@interface YTMActionRowView : UIView
@end

@interface MDCButton : UIButton
- (void)ytm_sizeToFitWithSize:(int)arg1;
@end

@interface YTMAlertView : GOOAlertView
@end
