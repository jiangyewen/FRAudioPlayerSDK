//
//  FRAudioPlayer.h
//  FRAudioPlayerSDK
//
//  Created by frankyjiang on 2020/12/22.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FRAudioPlayerState) {
    FRAudioPlayerStateBuffering = 1,
    FRAudioPlayerStatePlaying = 2,
    FRAudioPlayerStateStopped = 3,
    FRAudioPlayerStatePause = 4,
    FRAudioPlayerStateError = 5,
};

typedef void(^FRAudioStateChangedBlock)(FRAudioPlayerState fromState, FRAudioPlayerState currentState);
typedef void(^FRAudioProgressChangedBlock)(CGFloat currentTime, CGFloat duration);

@interface FRAudioPlayer : NSObject
@property(nonatomic, assign, readonly) FRAudioPlayerState state;
@property(nonatomic, assign, readonly) CGFloat loadedProgress;
@property(nonatomic, assign, readonly) CGFloat duration;
@property(nonatomic, assign, readonly) CGFloat currentTime;
@property(nonatomic, assign, readonly) CGFloat progress;
@property(nonatomic, strong, readonly) AVPlayerItem *currentPlayerItem;
@property (readonly, strong, readonly) NSError *error;

@property(nonatomic, assign) BOOL loopPlay;

@property(nonatomic, copy) FRAudioStateChangedBlock stateChangedBlock;
@property(nonatomic, copy) FRAudioProgressChangedBlock progressChangedBlock;
- (void)playWithUrl:(NSURL *)url;
- (void)seekToTime:(CGFloat)seconds;

- (void)play;
- (void)pause;
- (void)stop;
@end

NS_ASSUME_NONNULL_END
