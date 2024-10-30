#import <YouTubeHeader/_ASCollectionViewCell.h>
#import <YouTubeHeader/ASCollectionView.h>
#import <YouTubeHeader/ELMCellNode.h>
#import <YouTubeHeader/ELMContainerNode.h>
#import <YouTubeHeader/ELMNodeFactory.h>
#import <YouTubeHeader/ELMTextNode.h>
#import <YouTubeHeader/YTLikeStatus.h>
#import <YouTubeHeader/YTILikeButtonRenderer.h>
#import <YouTubeMusicHeader/MDCButton.h>
#import <YouTubeMusicHeader/YTMActionRowView.h>
#import <YouTubeMusicHeader/YTMNowPlayingViewController.h>
#import <HBLog.h>
#import "../Return-YouTube-Dislikes/API.h"
#import "../Return-YouTube-Dislikes/Vote.h"
#import "../Return-YouTube-Dislikes/TweakSettings.h"

static NSCache <NSString *, NSDictionary *> *cache;

__strong ELMTextNode *likeTextNode = nil;
__strong ELMTextNode *dislikeTextNode = nil;
__strong NSMutableAttributedString *mutableDislikeText = nil;

int overrideNodeCreation = 0;

static BOOL isVideoScrollabelActionBar(ASCollectionView *collectionView) {
    return [collectionView.accessibilityIdentifier isEqualToString:@"id.video.scrollable_action_bar"];
}

static NSString *getVideoId(ASDisplayNode *containerNode) {
    YTMNowPlayingViewController *vc = (YTMNowPlayingViewController *)[containerNode closestViewController];
    if (![vc isKindOfClass:%c(YTMNowPlayingViewController)]) return nil;
    return vc.likeButtonRenderer.target.videoId;
}

static void getVoteAndModifyButtons(
    NSString *videoId,
    int pairMode,
    void (^likeHandler)(NSString *likeCount, NSNumber *likeNumber),
    void (^dislikeHandler)(NSString *dislikeCount, NSNumber *dislikeNumber)
) {
    getVoteFromVideoWithHandler(cache, videoId, maxRetryCount, ^(NSDictionary *data, NSString *error) {
        HBLogDebug(@"RYMD: Vote data for video %@: %@", videoId, data);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ExactLikeNumber() && error == nil) {
                NSNumber *likeNumber = data[@"likes"];
                NSString *likeCount = formattedLongNumber(likeNumber, nil);
                if (likeCount && likeHandler) {
                    HBLogDebug(@"RYMD: Set like count for %@ to %@", videoId, likeCount);
                    likeHandler(likeCount, likeNumber);
                }
            }
            NSNumber *dislikeNumber = data[@"dislikes"];
            NSString *dislikeCount = getNormalizedDislikes(dislikeNumber, error);
            if (dislikeHandler) {
                HBLogDebug(@"RYMD: Set dislike count for %@ to %@", videoId, dislikeCount);
                dislikeHandler(dislikeCount, dislikeNumber);
            }
        });
    });
}

%hook YTMActionRowView

- (void)updateLikeDislikeButtonWithRenderer:(YTILikeButtonRenderer *)renderer {
    %orig;
    if (!TweakEnabled() || renderer.target.videoId == nil) return;
    MDCButton *likeButton = [self valueForKey:@"_likeButton"];
    MDCButton *dislikeButton = [self valueForKey:@"_dislikeButton"];
    [dislikeButton setTitle:FETCHING forState:UIControlStateNormal];
    [dislikeButton ytm_sizeToFitWithSize:1];
    [self setNeedsLayout];
    getVoteFromVideoWithHandler(cache, renderer.target.videoId, maxRetryCount, ^(NSDictionary *data, NSString *error) {
        if (ExactLikeNumber()) {
            NSString *likeText = getNormalizedDislikes(data[@"likes"], error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [likeButton setTitle:likeText forState:UIControlStateNormal];
                [likeButton ytm_sizeToFitWithSize:1];
                [self setNeedsLayout];
            });
        }
        NSString *dislikeText = getNormalizedDislikes(data[@"dislikes"], error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [dislikeButton setTitle:dislikeText forState:UIControlStateNormal];
            [dislikeButton ytm_sizeToFitWithSize:1];
            [self setNeedsLayout];
        });
    });
}

%end

%hook ASCollectionView

- (ELMCellNode *)nodeForItemAtIndexPath:(NSIndexPath *)indexPath {
    ELMCellNode *node = %orig;
    if (isVideoScrollabelActionBar(self) && TweakEnabled()) {
        _ASCollectionViewCell *likeDislikeCell = [self.subviews firstObject];
        ASDisplayNode *containerNode = [likeDislikeCell node];
        NSString *videoId = getVideoId(containerNode);
        if (videoId == nil) return node;
        int pairMode = -1;
        BOOL isDislikeButtonModified = NO;
        do {
            containerNode = [containerNode.yogaChildren firstObject];
            if (containerNode.yogaChildren.count == 2)
                containerNode = containerNode.yogaChildren[1];
        } while (containerNode.yogaChildren.count == 1);
        ELMContainerNode *likeNode = [containerNode.yogaChildren firstObject];
        // if (![likeNode.accessibilityIdentifier isEqualToString:@"id.video.like.button"]) {
        //     HBLogDebug(@"RYMD: Like button not found, instead found %@", likeNode.accessibilityIdentifier);
        //     return node;
        // }
        if (likeNode.yogaChildren.count == 2) {
            ELMContainerNode *dislikeNode = [containerNode.yogaChildren lastObject];
            isDislikeButtonModified = dislikeNode.yogaChildren.count == 2;
            id targetNode = likeNode.yogaChildren[1];
            likeTextNode = (ELMTextNode *)targetNode;
            if (isDislikeButtonModified)
                dislikeTextNode = dislikeNode.yogaChildren[1];
            else {
                id elementContext = [likeTextNode valueForKey:@"_context"];
                overrideNodeCreation = 2;
                dislikeTextNode = [[%c(ELMNodeFactory) sharedInstance] nodeWithElement:likeTextNode.element materializationContext:&elementContext];
                overrideNodeCreation = 0;
                mutableDislikeText = [[NSMutableAttributedString alloc] initWithAttributedString:likeTextNode.attributedText];
                dislikeTextNode.attributedText = mutableDislikeText;
                [dislikeNode addYogaChild:dislikeTextNode];
                [dislikeNode.view addSubview:dislikeTextNode.view];
                pairMode = 0;
            }
        } else {
            dislikeTextNode = likeNode.yogaChildren[1];
            if (![dislikeTextNode isKindOfClass:%c(ELMTextNode)]) return node;
            mutableDislikeText = [[NSMutableAttributedString alloc] initWithAttributedString:dislikeTextNode.attributedText];
            mutableDislikeText.mutableString.string = FETCHING;
            dislikeTextNode.attributedText = mutableDislikeText;
        }
        BOOL shouldFetchVote = ExactLikeNumber() || !isDislikeButtonModified;
        if (shouldFetchVote) {
            getVoteAndModifyButtons(
                videoId,
                pairMode,
                ^(NSString *likeCount, NSNumber *likeNumber) {
                    NSMutableAttributedString *mutableLikeText = [[NSMutableAttributedString alloc] initWithAttributedString:likeTextNode.attributedText];
                    mutableLikeText.mutableString.string = likeCount;
                    likeTextNode.attributedText = mutableLikeText;
                    likeTextNode.accessibilityLabel = likeCount;
                },
                ^(NSString *dislikeCount, NSNumber *dislikeNumber) {
                    if (isDislikeButtonModified) return;
                    NSString *dislikeString;
                    switch (pairMode) {
                        case -1:
                            dislikeString = dislikeCount;
                            break;
                        case 0:
                            dislikeString = [NSString stringWithFormat:@"  %@ ", dislikeCount];
                            break;
                    }
                    mutableDislikeText.mutableString.string = dislikeString;
                    dislikeTextNode.attributedText = mutableDislikeText;
                    dislikeTextNode.accessibilityLabel = dislikeCount;
                }
            );
        }
    }
    return node;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    %orig;
    if (isVideoScrollabelActionBar(self) && TweakEnabled() && dislikeTextNode) {
        NSString *dislikeText = dislikeTextNode.attributedText.string;
        mutableDislikeText = [[NSMutableAttributedString alloc] initWithAttributedString:likeTextNode.attributedText];
        mutableDislikeText.mutableString.string = dislikeText;
        dislikeTextNode.attributedText = mutableDislikeText;
    }
}

%end

%hook ELMNodeFactory

- (Class)classForElement:(id)element materializationContext:(const void *)context {
    switch (overrideNodeCreation) {
        case 2:
            return %c(ELMTextNode);
        default:
            return %orig;
    }
}

%end

%hook YTLikeService

- (void)makeRequestWithStatus:(YTLikeStatus)likeStatus target:(YTILikeTarget *)target clickTrackingParams:(id)arg3 requestParams:(id)arg4 responseBlock:(id)arg5 errorBlock:(id)arg6 {
    if (TweakEnabled() && VoteSubmissionEnabled())
        sendVote(target.videoId, likeStatus);
    %orig;
}

- (void)makeRequestWithStatus:(YTLikeStatus)likeStatus target:(YTILikeTarget *)target clickTrackingParams:(id)arg3 queueContextParams:(id)arg4 requestParams:(id)arg5 responseBlock:(id)arg6 errorBlock:(id)arg7 {
    if (TweakEnabled() && VoteSubmissionEnabled())
        sendVote(target.videoId, likeStatus);
    %orig;
}

%end

%ctor {
    cache = [NSCache new];
    %init;
}
