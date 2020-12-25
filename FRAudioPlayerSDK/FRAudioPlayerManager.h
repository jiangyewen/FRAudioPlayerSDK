//
//  FRAudioPlayerManager.h
//  FRAudioPlayerSDK
//
//  Created by frankyjiang on 2020/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FRAudioPlayerManager : NSObject
@property(nonatomic, copy) dispatch_block_t nextTrackEventBlock;
@property(nonatomic, copy) dispatch_block_t prevtTrackEventBlock;
@property(nonatomic, strong, readonly) FRAudioPlayer *player;
@property(nonatomic, assign, readonly) BOOL isPlaying;
@property(nonatomic, strong, readonly) NSURL *currentURL;
+ (instancetype)sharedInstance;
- (void)playWithUrl:(NSURL *)url;
- (void)seekToTime:(CGFloat)seconds;

- (void)play;
- (void)pause;
- (void)stop;
- (void)togglePlayAndPause;

- (void)configNowPlayingWithTitle:(NSString *)title artist:(NSString *)artist coverImage:(UIImage *)coverImage;
@end

NS_ASSUME_NONNULL_END
