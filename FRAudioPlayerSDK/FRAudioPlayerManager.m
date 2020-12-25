//
//  FRAudioPlayerManager.m
//  FRAudioPlayerSDK
//
//  Created by frankyjiang on 2020/12/24.
//

#import "FRAudioPlayer.h"
#import "FRAudioPlayerManager.h"
#import <MediaPlayer/MediaPlayer.h>

@interface FRAudioPlayerManager ()
@property(nonatomic, strong) FRAudioPlayer *player;
@property(nonatomic, strong) NSURL *currentURL;
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
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:NULL];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAudioSessionInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:nil];
        
        [self configRemoteControlEvent];
        
      
    }

    return self;
}

- (void)togglePlayAndPause {
    if (self.isPlaying) {
        [self pause];
    } else {
        [self play];
    }
}

- (void)handleAudioSessionInterruption:(NSNotification*)notification {
    NSNumber *interruptionType = [[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey];
    NSNumber *interruptionOption = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
    switch (interruptionType.unsignedIntegerValue) {
        case AVAudioSessionInterruptionTypeBegan: {
            [self pause];
        } break;
        case AVAudioSessionInterruptionTypeEnded:{
            if (interruptionOption.unsignedIntegerValue == AVAudioSessionInterruptionOptionShouldResume) {
                [self.player play];
            }
        } break;
        default:
            break;
    }
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

- (BOOL)isPlaying {
    if (!_player) {
        return  NO;
    }
    FRAudioPlayerState playState = self.player.state;
    BOOL isPlaying = (playState == FRAudioPlayerStateBuffering || playState ==  FRAudioPlayerStatePlaying);
    return isPlaying;
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

#pragma mark - remote control center and now playing
- (void)configNowPlayingWithTitle:(NSString *)title artist:(NSString *)artist coverImage:(UIImage *)coverImage {
    title = title.length > 0 ? title : @"";
    artist = artist.length > 0 ? artist : @"";
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:CGSizeMake(100, 100)
                                                                  requestHandler:^UIImage *_Nonnull(CGSize size) {
                                                                      return coverImage;
                                                                  }];
    NSDictionary *info = @ {
        MPMediaItemPropertyTitle : title,
        MPMediaItemPropertyArtist : artist,
        MPMediaItemPropertyArtwork : artwork,
    };
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
}

- (void)configRemoteControlEvent {
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.togglePlayPauseCommand setEnabled:YES];
    [commandCenter.playCommand setEnabled:YES];
    [commandCenter.pauseCommand setEnabled:YES];
    [commandCenter.nextTrackCommand setEnabled:YES];
    [commandCenter.previousTrackCommand setEnabled:YES];
    [commandCenter.togglePlayPauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self togglePlayAndPause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.playCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self play];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.pauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.nextTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if (self.nextTrackEventBlock) {
            self.nextTrackEventBlock();
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.previousTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if (self.prevtTrackEventBlock) {
            self.prevtTrackEventBlock();
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.stopCommand setEnabled:NO];
    [commandCenter.skipForwardCommand setEnabled:NO];
    [commandCenter.skipBackwardCommand setEnabled:NO];
    [commandCenter.enableLanguageOptionCommand setEnabled:NO];
    [commandCenter.disableLanguageOptionCommand setEnabled:NO];
    [commandCenter.changeRepeatModeCommand setEnabled:NO];
    [commandCenter.changePlaybackRateCommand setEnabled:NO];
    [commandCenter.changeShuffleModeCommand setEnabled:NO];
    // Seek Commands
    [commandCenter.seekForwardCommand setEnabled:NO];
    [commandCenter.seekBackwardCommand setEnabled:NO];
    [commandCenter.changePlaybackPositionCommand setEnabled:NO];
    
    [commandCenter.ratingCommand setEnabled:NO];
    [commandCenter.likeCommand setEnabled:NO];
    [commandCenter.dislikeCommand setEnabled:NO];
    [commandCenter.bookmarkCommand setEnabled:NO];
}
@end
