#import <YouTubeHeader/YTLikeStatus.h>
#import <YouTubeHeader/YTILikeButtonRenderer.h>
#import <YouTubeMusicHeader/MDCButton.h>
#import <YouTubeMusicHeader/YTMActionRowView.h>
#import <HBLog.h>
#import "../Return-YouTube-Dislikes/API.h"
#import "../Return-YouTube-Dislikes/Vote.h"
#import "../Return-YouTube-Dislikes/TweakSettings.h"

static NSCache <NSString *, NSDictionary *> *cache;

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
