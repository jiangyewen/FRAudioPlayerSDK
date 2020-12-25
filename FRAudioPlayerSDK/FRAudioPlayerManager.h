//
//  FRAudioPlayerManager.h
//  FRAudioPlayerSDK
//
//  Created by frankyjiang on 2020/12/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FRAudioPlayerManager : NSObject
@property(nonatomic, strong, readonly) FRAudioPlayer *player;
@property(nonatomic, assign, readonly) BOOL isPlaying;
+ (instancetype)sharedInstance;
- (void)playWithUrl:(NSURL *)url;
- (void)seekToTime:(CGFloat)seconds;

- (void)play;
- (void)pause;
- (void)stop;
@end

NS_ASSUME_NONNULL_END
