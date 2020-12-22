//
//  FRAudioPlayer.m
//  FRAudioPlayerSDK
//
//  Created by frankyjiang on 2020/12/22.
//

#import "FRAudioPlayer.h"

static NSString *const kFRAudioPlayerKeyPathRate = @"rate";
static NSString *const kFRAudioPlayerItemKeyPathStatus = @"status";
static NSString *const kFRAudioPlayerItemKeyPathLoadedTimeRanges = @"loadedTimeRanges";
static NSString *const kFRAudioPlayerItemKeyPathPlaybackBufferEmpty = @"playbackBufferEmpty";
static NSString *const kFRAudioPlayerItemKeyPathPlaybackLikelyToKeepUp = @"playbackLikelyToKeepUp";

@interface FRAudioPlayer ()
@property(nonatomic, assign, readwrite) FRAudioPlayerState state;
@property(nonatomic, assign, readwrite) CGFloat loadedProgress;
@property(nonatomic, assign, readwrite) CGFloat duration;
@property(nonatomic, assign, readwrite) CGFloat currentTime;
@property(nonatomic, assign, readwrite) CGFloat progress;
@property(nonatomic, strong, readwrite) AVPlayerItem *currentPlayerItem;
@property(nonatomic, strong) AVPlayer *player;
@property(nonatomic, strong) NSObject *playbackTimeObserver;
@property(nonatomic, weak) id progressObserver;
@end

@implementation FRAudioPlayer
#pragma mark -dealloc
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.progressObserver) {
        [self.player removeTimeObserver:self.progressObserver];
        self.progressObserver = nil;
    }
}

//清空播放器监听属性
- (void)releasePlayer {
    [self.currentPlayerItem removeObserver:self forKeyPath:kFRAudioPlayerItemKeyPathStatus];
    [self.currentPlayerItem removeObserver:self forKeyPath:kFRAudioPlayerItemKeyPathLoadedTimeRanges];
    [self.currentPlayerItem removeObserver:self forKeyPath:kFRAudioPlayerItemKeyPathPlaybackBufferEmpty];
    [self.currentPlayerItem removeObserver:self forKeyPath:kFRAudioPlayerItemKeyPathPlaybackLikelyToKeepUp];
    [self.player removeObserver:self forKeyPath:kFRAudioPlayerKeyPathRate];
    [self.player removeTimeObserver:self.playbackTimeObserver];
    self.playbackTimeObserver = nil;
    self.currentPlayerItem = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self resetPlayer];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidPlayToEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemPlaybackStalled:)
                                                     name:AVPlayerItemPlaybackStalledNotification
                                                   object:nil];
    }

    return self;
}

- (void)resetPlayer {
    self.state = FRAudioPlayerStateStopped;
    self.loadedProgress = 0;
    self.duration = 0;
    self.currentTime = 0;
}

- (void)playWithUrl:(NSURL *)url {
    [self resetPlayer];

    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    self.currentPlayerItem = item;
    if (!self.player) {
        self.player = [AVPlayer playerWithPlayerItem:self.currentPlayerItem];
    } else {
        [self.player pause];
        [self.player replaceCurrentItemWithPlayerItem:self.currentPlayerItem];
    }

    self.state = FRAudioPlayerStateBuffering;
    [self play];
    [self.player addObserver:self
                  forKeyPath:kFRAudioPlayerKeyPathRate
                     options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                     context:NULL];
    [self.currentPlayerItem addObserver:self
                             forKeyPath:kFRAudioPlayerItemKeyPathStatus
                                options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                context:NULL];
    [self.currentPlayerItem addObserver:self
                             forKeyPath:kFRAudioPlayerItemKeyPathLoadedTimeRanges
                                options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                context:NULL];
    [self.currentPlayerItem addObserver:self
                             forKeyPath:kFRAudioPlayerItemKeyPathPlaybackBufferEmpty
                                options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                context:NULL];
    [self.currentPlayerItem addObserver:self
                             forKeyPath:kFRAudioPlayerItemKeyPathPlaybackLikelyToKeepUp
                                options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                context:NULL];
    //监控时间进度
    __weak typeof(self) weakSelf = self;
    self.progressObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                                      queue:dispatch_get_main_queue()
                                                                 usingBlock:^(CMTime time) {
                                                                     __strong typeof(self) self = weakSelf;
                                                                     CGFloat current = CMTimeGetSeconds(time);
                                                                     CGFloat total = CMTimeGetSeconds([self.currentPlayerItem duration]);
                                                                     if (total > 0.f && self.progressChangedBlock) {
                                                                         self.progressChangedBlock(current, total);
                                                                     }
                                                                 }];
}

#pragma mark - public methods
- (NSError *)error {
    return self.currentPlayerItem.error;
}
- (void)seekToTime:(CGFloat)seconds {
    if (self.state == FRAudioPlayerStateStopped) {
        return;
    }
    seconds = MAX(0, seconds);
    seconds = MIN(seconds, self.duration);
    [self.player pause];
    [self.player seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC)
            completionHandler:^(BOOL finished) {
                [self play];
                if (!self.currentPlayerItem.isPlaybackLikelyToKeepUp) {
                    self.state = FRAudioPlayerStateBuffering;
                }
            }];
}

- (void)play {
    if (!self.currentPlayerItem || self.state == FRAudioPlayerStatePlaying) {
        return;
    }
    [self.player play];
}

- (void)pause {
    if (!self.currentPlayerItem || self.state == FRAudioPlayerStatePause) {
        return;
    }
    self.state = FRAudioPlayerStatePause;
    [self.player pause];
}

- (void)stop {
    if (self.state == FRAudioPlayerStateStopped) {
        return;
    }
    self.loadedProgress = 0;
    self.duration = 0;
    self.currentTime = 0;

    self.state = FRAudioPlayerStateStopped;
    [self.player pause];
    [self releasePlayer];
}

- (CGFloat)progress {
    if (self.duration > 0) {
        return self.currentTime / self.duration;
    }
    return 0;
}

#pragma mark - handle notification and observer callbacks
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:kFRAudioPlayerKeyPathRate]) {
        if (self.player.rate == 1.f) {
            self.state = FRAudioPlayerStatePlaying;
        } else if (self.player.rate == 0.f) {
            self.state = FRAudioPlayerStatePause;
        }
    } else if ([keyPath isEqualToString:kFRAudioPlayerItemKeyPathStatus]) {
        if ([self.currentPlayerItem status] == AVPlayerStatusReadyToPlay) {
            if (self.state != FRAudioPlayerStatePause) {
                [self monitoringPlayback:self.currentPlayerItem];  // 给播放器添加计时器
            }
        } else if (self.currentPlayerItem.status == AVPlayerStatusFailed || self.currentPlayerItem.status == AVPlayerStatusUnknown) {
            [self stop];
            self.state = FRAudioPlayerStateError;
        }
    } else if ([keyPath isEqualToString:kFRAudioPlayerItemKeyPathLoadedTimeRanges]) {
        [self calculateDownloadProgress:self.currentPlayerItem];
    } else if ([keyPath isEqualToString:kFRAudioPlayerItemKeyPathPlaybackBufferEmpty]) {
        if (self.currentPlayerItem.isPlaybackBufferEmpty || !self.currentPlayerItem.playbackLikelyToKeepUp) {
            self.state = FRAudioPlayerStateBuffering;
        }
    } else if ([keyPath isEqualToString:kFRAudioPlayerItemKeyPathPlaybackLikelyToKeepUp]) {
        if (self.currentPlayerItem.playbackLikelyToKeepUp) {
            if (self.state != FRAudioPlayerStatePause) {
                [self play];
            }
        } else {
            self.state = FRAudioPlayerStateBuffering;
        }
    }
}

- (void)playerItemDidPlayToEnd:(NSNotification *)notification {
    if (notification.object == self.currentPlayerItem) {
        [self stop];
    }
}

- (void)playerItemPlaybackStalled:(NSNotification *)notification {
    if (notification.object == self.currentPlayerItem) {
        [self setState:FRAudioPlayerStateBuffering];
    }
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    self.duration = playerItem.duration.value / playerItem.duration.timescale;  //视频总时间
    [self play];
    __weak typeof(self) weakSelf = self;
    if (_playbackTimeObserver) {
        [_player removeTimeObserver:_playbackTimeObserver];
    }
    self.playbackTimeObserver =
            [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                      queue:NULL
                                                 usingBlock:^(CMTime time) {
                                                     __strong typeof(self) self = weakSelf;
                                                     CGFloat current = playerItem.currentTime.value / (playerItem.currentTime.timescale * 1.0);
                                                     if (self.currentTime != current) {
                                                         self.currentTime = current;
                                                         if (self.currentTime > self.duration) {
                                                             self.duration = self.currentTime;
                                                         }
                                                     }
                                                 }];
}

- (void)calculateDownloadProgress:(AVPlayerItem *)playerItem {
    NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];  // 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval timeInterval = startSeconds + durationSeconds;  // 计算缓冲总进度
    CMTime duration = playerItem.duration;
    CGFloat totalDuration = CMTimeGetSeconds(duration);
    self.loadedProgress = timeInterval / totalDuration;
}

- (void)setLoadedProgress:(CGFloat)loadedProgress {
    if (_loadedProgress == loadedProgress) {
        return;
    }

    _loadedProgress = loadedProgress;
}

- (void)setState:(FRAudioPlayerState)state {
    if (_state == state) {
        return;
    }
    FRAudioPlayerState fromState = _state;
    _state = state;
    if (self.stateChangedBlock) {
        self.stateChangedBlock(fromState, _state);
    }
}
@end
