//
//  ViewController.m
//  AVPlayerTest
//
//  Created by 包宇津 on 2017/9/6.
//  Copyright © 2017年 baoyujin. All rights reserved.
//

#import "ViewController.h"
#import  <AVFoundation/AVFoundation.h>
#import <Masonry.h>
@interface ViewController ()
@property (nonatomic, strong) AVPlayer *player;  //播放器对象
@property (nonatomic, strong) UIView *container;  //播放器容器
@property (nonatomic, strong) UIButton *playOrPause;
@property (nonatomic, strong) UIProgressView *progress; //播放进度
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupViews];
    [self setupUI];
    [self.player play];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)dealloc {
    [self removeObserverFromPlayerItem:self.player.currentItem];
    [self removeNotification];
}
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)playbackFinished:(NSNotification *)notification {
    NSLog(@"视屏播放完成:");
}
#pragma mark --Views
- (void)setupViews{
    __weak typeof (self) weakSelf = self;
    [self.view addSubview:self.container];
    [_container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(weakSelf.view.mas_left);
        make.right.mas_equalTo(weakSelf.view.mas_right);
        make.top.mas_equalTo(weakSelf.mas_topLayoutGuide);
        make.height.equalTo(@300);
    }];
    
    [self.view addSubview:self.playOrPause];
    [_playOrPause mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.container.mas_bottom).offset(40);
        make.centerX.mas_equalTo(weakSelf.container.mas_centerX);
        make.height.equalTo(@40);
        make.width.equalTo(@80);
    }];
    [self.view addSubview:self.progress];
    [_progress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(weakSelf.view.mas_left).offset(30);
        make.top.mas_equalTo(weakSelf.container.mas_bottom).offset(20);
        make.height.mas_equalTo(@10);
        make.width.mas_equalTo(@200);
        make.centerX.mas_equalTo(weakSelf.container.mas_centerX);
    }];
}

- (void)setupUI {
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = self.container.frame;
    [self.container.layer addSublayer:playerLayer];
}
- (AVPlayerItem *)getPlayItem:(int)videoIndex {
    NSString *urlStr = [NSString stringWithFormat:@"http://sports.cctv.com/2017/09/06/VIDEDsBTrXGuwUbarPOHx0pA170906.shtml"];
    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlStr];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    [self addProgressObserver];
    [self addObserverToPlayerItem:playerItem];
    return playerItem;
    
}
#pragma mark --Lazy load
- (AVPlayer *)player {
    if (_player) {
        return _player;
    }
    AVPlayerItem *playerItem = [self getPlayItem:0];
    _player = [AVPlayer playerWithPlayerItem:playerItem];
    return _player;
}
- (UIView *)container {
    if (_container) {
        return _container;
    }
    _container = [[UIView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 300)];
    _container.backgroundColor = [UIColor clearColor];
    return _container;
}

- (UIProgressView *)progress {
    if (_progress) {
        return _progress;
    }
    _progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progress.progress = 0.f;
    return _progress;
}
- (UIButton *)playOrPause {
    if (_playOrPause) {
        return _playOrPause;
    }
    _playOrPause = [[UIButton alloc] init];
    _playOrPause.titleLabel.font = [UIFont systemFontOfSize:16];
    [_playOrPause setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [_playOrPause setTitle:@"播放" forState:UIControlStateNormal];
    [_playOrPause setTitle:@"暂停" forState:UIControlStateSelected];
    return _playOrPause;
}

#pragma mark --监控
- (void)addProgressObserver {
    AVPlayerItem *playerItem = self.player.currentItem;
    UIProgressView *progress = self.progress;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds([playerItem duration]);
        NSLog(@"当前已经播放%.2fs",current);
        if (current) {
            [progress setProgress:(current / total) animated:YES];
        }
    }];
}

- (void)addObserverToPlayerItem:(AVPlayerItem *)playerItem {
    //AVPlayer 有一个Status属性，可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerItem *playerItme = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if (status == AVPlayerStatusReadyToPlay) {
            NSLog(@"正在播放。。。，视屏总长度%.2f",CMTimeGetSeconds(playerItme.duration));
        }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            NSArray *array = playerItme.loadedTimeRanges;
            CMTimeRange timeRange = [array.firstObject CMTimeRangeValue]; //本次缓冲时间范围
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration);
            NSTimeInterval totalBuffer = startSeconds + durationSeconds;
            NSLog(@"共缓冲:%.2f",totalBuffer);
        }
    }
}

#pragma mark --UI 
- (void)playClick:(UIButton *)sender {
    if (self.player.rate == 0) {
        //暂停
        [sender setSelected:NO];
        [self.player play];
    }else if (self.player.rate == 1) {
        //正在播放
        [sender setSelected:YES];
        [self.player pause];
    }
}

@end
