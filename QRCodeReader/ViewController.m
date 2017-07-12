//
//  ViewController.m
//  QRCodeReader
//
//  Created by Miguel Hernandez on 7/11/17.
//  Copyright © 2017 Miguel Hernandez. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *viewPreview;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonStart;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;
@property (weak, nonatomic) IBOutlet UILabel *labelInfo;

@property (nonatomic) BOOL isReading;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;


-(BOOL)startReading;
-(void)stopReading;

- (IBAction)startStopReading:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _isReading = NO;
  _captureSession = nil;
  
}

- (BOOL)startReading {
  
  NSError *error;
  
  AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  
  AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
  if (!input) {
    NSLog(@"%@", [error localizedDescription]);
    return NO;
  }
  
  _captureSession = [[AVCaptureSession alloc] init];
  [_captureSession addInput:input];
  
  AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
  [_captureSession addOutput:captureMetadataOutput];
  
  dispatch_queue_t dispatchQueue;
  dispatchQueue = dispatch_queue_create("myQueue", NULL);
  [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
  [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
  
  _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
  [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
  [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
  [_viewPreview.layer addSublayer:_videoPreviewLayer];
  
  [_captureSession startRunning];
  
  return YES;
}


-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
  
  if (metadataObjects != nil && [metadataObjects count] > 0) {
    
    AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
    
    if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
      
      [_labelStatus performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
      
      [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
      
      [_buttonStart performSelectorOnMainThread:@selector(setTitle:) withObject:@"Start!" waitUntilDone:NO];
      
      _isReading = NO;
    }
  }
}


- (IBAction)startStopReading:(id)sender {
  
  if (!_isReading) {
    
    if ([self startReading]) {
      [_labelInfo setHidden:YES];
      [_buttonStart setTitle:@"Stop"];
      [_labelStatus setText:@"Scanning for QR Code..."];
    }
    
  } else {
    [self stopReading];
    [_labelInfo setHidden:NO];
    [_buttonStart setTitle:@"Start!"];
  }
  
  _isReading = !_isReading;
}


-(void)stopReading{
  [_captureSession stopRunning];
  _captureSession = nil;
  
  [_videoPreviewLayer removeFromSuperlayer];
}

@end
