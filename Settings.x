#import <YouTubeHeader/GOOHeaderViewController.h>
#import <YouTubeHeader/YTUIUtils.h>
#import <YouTubeMusicHeader/YTMAlertView.h>
#import <YouTubeMusicHeader/YTMSettingsResponseViewController.h>
#import <YouTubeMusicHeader/YTMSettingsSectionController.h>
#import <rootless.h>
#import "../Return-YouTube-Dislikes/Settings.h"
#import "../Return-YouTube-Dislikes/TweakSettings.h"

NSBundle *RYMDBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"RYMD" ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/Application Support/RYMD.bundle")];
    });
    return bundle;
}

%hook YTMSettingsResponseViewController

- (NSArray <YTMSettingsSectionController *> *)sectionControllersFromSettingsResponse:(id)response {
    NSBundle *tweakBundle = RYMDBundle();
    NSMutableArray <YTMSettingsSectionController *> *newSectionControllers = [NSMutableArray arrayWithArray:%orig];
    YTMSettingsSectionItem *settingMenuItem = [%c(YTMSettingsSectionItem) itemWithTitle:LOC(@"SETTINGS_TITLE") accessibilityIdentifier:nil detailTextBlock:nil selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) { return YES; }];
    settingMenuItem.indicatorIconType = 221;
    settingMenuItem.inkEnabled = YES;
    settingMenuItem.selectBlock = ^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
        YTMSettingsResponseViewController *responseVC = [[%c(YTMSettingsResponseViewController) alloc] initWithService:[self valueForKey:@"_service"] parentResponder:self];
        responseVC.title = [%c(YTUIUtils) appPortraitWidth] <= 320 ? @(SHORT_TWEAK_NAME) : @(TWEAK_NAME);
        NSMutableArray <YTMSettingsSectionItem *> *settingItems = [NSMutableArray new];
        YTMSettingsSectionItem *enabled = [%c(YTMSettingsSectionItem) switchItemWithTitle:LOC(@"ENABLED")
            titleDescription:nil
            accessibilityIdentifier:nil
            switchOn:TweakEnabled()
            switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:EnabledKey];
                return YES;
            }
            settingItemId:0];
        [settingItems addObject:enabled];
        YTMSettingsSectionItem *vote = [%c(YTMSettingsSectionItem) switchItemWithTitle:LOC(@"ENABLE_VOTE_SUBMIT")
            titleDescription:[NSString stringWithFormat:LOC(@"ENABLE_VOTE_SUBMIT_DESC"), @(API_URL)]
            accessibilityIdentifier:nil
            switchOn:VoteSubmissionEnabled()
            switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                enableVoteSubmission(enabled);
                return YES;
            }
            settingItemId:0];
        [settingItems addObject:vote];
        YTMSettingsSectionItem *exactDislike = [%c(YTMSettingsSectionItem) switchItemWithTitle:LOC(@"EXACT_DISLIKE_NUMBER")
            titleDescription:[NSString stringWithFormat:LOC(@"EXACT_DISLIKE_NUMBER_DESC"), @"12345", [NSNumberFormatter localizedStringFromNumber:@(12345) numberStyle:NSNumberFormatterDecimalStyle]]
            accessibilityIdentifier:nil
            switchOn:ExactDislikeNumber()
            switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:ExactDislikeKey];
                return YES;
            }
            settingItemId:0];
        [settingItems addObject:exactDislike];
        YTMSettingsSectionItem *exactLike = [%c(YTMSettingsSectionItem) switchItemWithTitle:LOC(@"EXACT_LIKE_NUMBER")
            titleDescription:nil
            accessibilityIdentifier:nil
            switchOn:ExactLikeNumber()
            switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
                [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:ExactLikeKey];
                return YES;
            }
            settingItemId:0];
        [settingItems addObject:exactLike];
        YTMSettingCollectionSectionController *scsc = [[%c(YTMSettingCollectionSectionController) alloc] initWithTitle:@"" items:settingItems parentResponder:responseVC];
        [responseVC collectionViewController].sectionControllers = @[scsc];
        GOOHeaderViewController *headerVC = [[%c(GOOHeaderViewController) alloc] initWithContentViewController:responseVC];
        [self.navigationController pushViewController:headerVC animated:YES];
        return YES;
    };
    YTMSettingsSectionController *settings = [[%c(YTMSettingsSectionController) alloc] initWithTitle:@"" items:@[settingMenuItem] parentResponder:[self parentResponder]];
    settings.categoryID = 'rytd';
    [newSectionControllers insertObject:settings atIndex:0];
    return newSectionControllers;
}

%end

%ctor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:DidShowEnableVoteSubmissionAlertKey] && !VoteSubmissionEnabled()) {
        [defaults setBool:YES forKey:DidShowEnableVoteSubmissionAlertKey];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSBundle *tweakBundle = RYMDBundle();
            YTMAlertView *alertView = [%c(YTMAlertView) confirmationDialogWithAction:^{
                enableVoteSubmission(YES);
            } actionTitle:_LOC([NSBundle mainBundle], @"dialog.okay")];
            alertView.title = @(TWEAK_NAME);
            alertView.subtitle = [NSString stringWithFormat:LOC(@"WANT_TO_ENABLE"), @(API_URL), @(TWEAK_NAME), LOC(@"ENABLE_VOTE_SUBMIT")];
            [alertView show];
        });
    }
    %init;
}
