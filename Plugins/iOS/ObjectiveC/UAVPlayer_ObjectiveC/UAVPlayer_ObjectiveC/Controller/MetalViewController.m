//
//  MetalViewController.m
//  UAVPlayer_ObjectiveC
//
//  Created by HanGyo Jeong on 2020/03/04.
//  Copyright © 2020 HanGyoJeong. All rights reserved.
//

#import "MetalViewController.h"
#import "Matrix4.h"
#import <MobileCoreServices/MobileCoreServices.h>

static void* AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

# define ONE_FRAME_DURATION 0.03
# define LUMA_SLIDER_TAG 0
# define CHROMA_SLIDER_TAG 1

@implementation MetalViewController
{
    dispatch_queue_t videoOutputQueue;
    
    CADisplayLink *timer;
    CFTimeInterval lastFrameTimestamp;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initProperties];
    
    _avPlayer = [[AVPlayer alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self addObserver:self forKeyPath:@"avPlayer.currentItem.status" options:NSKeyValueObservingOptionNew context:AVPlayerItemStatusContext];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self removeObserver:self forKeyPath:@"avPlayer.currentItem.status" context:AVPlayerItemStatusContext];
}

- (void)initProperties
{
    lastFrameTimestamp = 0.0;
    
    _device = MTLCreateSystemDefaultDevice();
    
    _projectionMatrix = [Matrix4 makePerspectiveViewAngle:[Matrix4 degreesToRad:85.0]
                                             aspectRatio:self.view.bounds.size.width / self.view.bounds.size.height
                                                   nearZ:0.01
                                                    farZ:100];
    
    _metalLayer = [CAMetalLayer layer];
    _metalLayer.device = _device;
    _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    _metalLayer.framebufferOnly = YES;
    _metalLayer.frame = self.view.layer.frame;
    [self.view.layer addSublayer:_metalLayer];
    
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"basic_vertex"];
    id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"basic_fragment"];
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexProgram;
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    NSError *error;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if(error)
    {
        NSLog(@"Fail to make PipelineStateDescriptor");
        return;
    }
    
    _commandQueue = [_device newCommandQueue];
    
    timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(newFrame:)];
    [timer addToRunLoop:NSRunLoop.mainRunLoop forMode:NSDefaultRunLoopMode];
    [timer setPaused:YES];
    
    //Setup AVPlayerItemVideoOutput with the required pixelbuffer atttributes
    NSDictionary *pixelBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBuffAttributes];
    videoOutputQueue = dispatch_queue_create("VideoOutputQueue", DISPATCH_QUEUE_SERIAL);
    [_videoOutput setDelegate:self queue:videoOutputQueue];
}

- (void) render
{
    id<CAMetalDrawable> drawable = _metalLayer.nextDrawable;
    if(nil != drawable)
    {
        [_metalViewControllerDelegate renderObject:drawable];
    }
    else
    {
        NSLog(@"Fail to get metalDrawable Object");
        return;
    }
}

- (void) newFrame:(CADisplayLink *)displayLink
{
    if(0.0 == lastFrameTimestamp)
    {
        lastFrameTimestamp = displayLink.timestamp;
    }
    
    NSTimeInterval elapsed = displayLink.timestamp - lastFrameTimestamp;
    lastFrameTimestamp = displayLink.timestamp;
    
    [self gameloop:elapsed];
}

- (void) gameloop:(CFTimeInterval)timeSinceLastUpdate
{
    @autoreleasepool
    {
        [self render];
    }
}

//MARK: Utilities
- (void)startToPlay:(NSString*)assetURL
{
    NSLog(@"AssetURL path ; %@", assetURL);
    [_avPlayer pause];
    
    [self setupPlaybackForURL:[NSURL fileURLWithPath:assetURL]];
}

//MARK: Playback setup
- (void)setupPlaybackForURL:(NSURL*)URL
{
    //Remove video output from old item
    [[_avPlayer currentItem] removeOutput:_videoOutput];
    
    AVPlayerItem* item = [[AVPlayerItem alloc] initWithURL:URL];
    AVAsset* asset = [item asset];
    
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        if([asset statusOfValueForKey:@"tracks" error:nil] == AVKeyValueStatusLoaded)
        {
            NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if([tracks count] > 0)
            {
                //Choose the first video track
//                AVAssetTrack* videoTrack = [tracks objectAtIndex:0];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [item addOutput:self.videoOutput];
                    [self.avPlayer replaceCurrentItemWithPlayerItem:item];
                    [self.videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
                    [self.avPlayer play];
                });
            }
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if(context == AVPlayerItemStatusContext)
    {
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerItemStatusUnknown:
                break;
            case AVPlayerItemStatusReadyToPlay:
                
                break;
            case AVPlayerItemStatusFailed:
                
                break;
            default:
                break;
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
