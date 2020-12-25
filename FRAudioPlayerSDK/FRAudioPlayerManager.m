//
//  FRAudioPlayerManager.m
//  FRAudioPlayerSDK
//
//  Created by frankyjiang on 2020/12/24.
//

#import "FRAudioPlayer.h"
#import "FRAudioPlayerManager.h"

@interface FRAudioPlayerManager ()
@property(nonatomic, strong) FRAudioPlayer *player;
@property(nonatomic, copy) NSURL *currentURL;
@end

@implementation FRAudioPlayerManager

+ (instancetype)sharedInstance {
    static id s_singletion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_singletion = [[self.class alloc] init];
    });
    return s_singletion;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    }

    return self;
}

- (void)playWithUrl:(NSURL *)url {
    if (!url || url.absoluteString.length ==0) {
        return;
    }
    if ([url.absoluteString isEqualToString:self.currentURL.absoluteString]) {
        [self play];
    } else {
        [self stop];
        self.currentURL = url;
        self.player = [[FRAudioPlayer alloc] init];
        [self.player playWithUrl:url];
    }
}

- (void)seekToTime:(CGFloat)seconds {
    [self.player seekToTime:seconds];
}

- (void)play {
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)stop {
    [self.player stop];
    self.player = nil;
}
@end
