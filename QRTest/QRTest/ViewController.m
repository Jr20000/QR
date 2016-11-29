//
//  ViewController.m
//  QRTest
//
//  Created by Jr2000 on 2016/9/29.
//  Copyright © 2016年 Jr2000. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) BOOL isReading;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:UIColor.lightGrayColor];
    [self.navigationController.view setBackgroundColor:UIColor.lightGrayColor];

    [self initVaule];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initVaule
{
    _captureSession = nil;
    _isReading = NO;
    
    [_lblStatusTextField setDelegate:self];
}

- (IBAction)openQRCodeFromAlbum:(id)sender
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.allowsEditing = YES;
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:^{}];
    }else{
        // 用UIAlertView 顯示錯誤訊息
        [self alertAction:@"錯誤" alertMessage:@"設備不同意使用相冊, 請在設置->隱私權->照片中設定同意" actionWithTitle:@"Ok"];
    }
}

- (IBAction)startStopReading:(id)sender
{
    if (!_isReading)
    {
        if ([self startReading])
        {
            [_bbitemStart setTitle:@"Stop"];
            [_lblStatusTextField setText:@"Scanning for QR Code..."];
        }
    }
    else
    {
        [self stopReading];
        [_bbitemStart setTitle:@"Start!"];
    }
    
    _isReading = !_isReading;
}

- (IBAction)copyText:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard containsPasteboardTypes: [NSArray arrayWithObject:@"public.utf8-plain-text"]];
    pasteboard.string = [_lblStatusTextField text];
}

- (IBAction)createBarcode:(id)sender
{
    [self performSegueWithIdentifier:@"CreateQRCode" sender:self];
    
}

- (BOOL)startReading
{
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input)
    {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    // Initialize the captureSession object.
    _captureSession = [[AVCaptureSession alloc] init];
    // Set the input device on the capture session.
    [_captureSession addInput:input];
    
    // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    // Create a new serial dispatch queue.
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[captureMetadataOutput availableMetadataObjectTypes]];
    
    // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    
    // Start video capture.
    [_captureSession startRunning];
    
    return YES;
}

- (void)stopReading
{
    // Stop video capture and make the capture session object nil.
    [_captureSession stopRunning];
    _captureSession = nil;
    
    // Remove the video preview layer from the viewPreview view's layer.
    [_videoPreviewLayer removeFromSuperlayer];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate method implementation
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if (metadataObjects != nil && [metadataObjects count] > 0)
    {
        //NSLog(@"Result:%@", metadataObjects);
        // Get the metadata object.
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        
        // If the found metadata is equal to the QR code metadata then update the status label's text,
        // stop reading and change the bar button item's title and the flag's value.
        // Everything is done on the main thread.
        NSLog(@"data = %@", metadataObj);

        // 把結果顯示出來
        [_lblStatusTextField performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
        [_lblCodeType performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj type] waitUntilDone:NO];
        
        [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
        [_bbitemStart performSelectorOnMainThread:@selector(setTitle:) withObject:@"開始掃描" waitUntilDone:NO];
        _isReading = NO;
        
        [self checkupURL:[metadataObj stringValue]];
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //1.獲取選擇的圖片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    //2.初始化一個偵測器
    CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode
                                             context:nil
                                             options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        if (features.count >=1)
        {
            CIQRCodeFeature *feature = [features objectAtIndex:0];
            NSString *scannedResult = feature.messageString;

            [_lblStatusTextField performSelectorOnMainThread:@selector(setText:) withObject:scannedResult waitUntilDone:NO];
            [_lblCodeType performSelectorOnMainThread:@selector(setText:) withObject:@"org.iso.QRCode" waitUntilDone:NO];
            [self checkupURL:scannedResult];
        }
        else
        {
            [_lblStatusTextField performSelectorOnMainThread:@selector(setText:) withObject:@"" waitUntilDone:NO];
            [_lblCodeType performSelectorOnMainThread:@selector(setText:) withObject:@"編碼類型" waitUntilDone:NO];
            
            // 用UIAlertView 顯示錯誤訊息
            [self alertAction:@"提示" alertMessage:@"該圖片裡沒有包含QR Code" actionWithTitle:@"確定"];
        }
    }];
}

- (void)checkupURL:(NSString *)str
{
    if([str containsString:@"http://"])
    {
        [self conformActionAlert:str];
    }
}

- (void)conformActionAlert:(NSString *)str
{
    UIAlertController *urlAlertCtrl = [UIAlertController alertControllerWithTitle:nil
                                                                          message:@"打開網址"
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action)
                                   {
                                   }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"確定"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action)
                               {
                                   [self openUrl:str];
                               }];
    
    [urlAlertCtrl addAction:cancelAction];
    [urlAlertCtrl addAction:okAction];
    [self presentViewController:urlAlertCtrl animated:YES completion:nil];
}

- (void)openUrl:(NSString *)str
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str] options:@{} completionHandler:^(BOOL success) {
        NSLog(@"Open %d",success);
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_lblStatusTextField resignFirstResponder];
}

- (void)alertAction:(NSString *)controllerTitle alertMessage:(NSString *)message actionWithTitle:(NSString *)title
{
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:controllerTitle
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *alertAction =
    [UIAlertAction actionWithTitle:title
                             style:UIAlertActionStyleCancel
                           handler:^(UIAlertAction *action){}];
    
    [alertController addAction:alertAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
