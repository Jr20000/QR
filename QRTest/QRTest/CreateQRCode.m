//
//  CreateQRCode.m
//  QRTest
//
//  Created by Jr2000 on 2016/10/14.
//  Copyright © 2016年 Jr2000. All rights reserved.
//

#import "CreateQRCode.h"
#import <Photos/Photos.h>

@interface CreateQRCode ()
{
    NSArray *pickerCodeTitleArray;
}

@property (retain, nonatomic) IBOutlet UIPickerView *myCodePickView;
@property (weak, nonatomic) IBOutlet UIImageView *qrCodeImageView;
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;

@end

@implementation CreateQRCode

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.inputTextField setDelegate:self];
    [self initPickerViewMainViewParameter];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)createQRCodeBtn:(id)sender
{
    [self startGenerateQRcode:_inputTextField.text];
    [_inputTextField resignFirstResponder];
}

-(void)startGenerateQRcode:(NSString *)code
{
    __weak CreateQRCode *weakSelf = self;
    NSInteger num = [_myCodePickView selectedRowInComponent:0];
    UIImage *generateImage;
    
    switch (num)
    {
        case 0:
            generateImage = [self generateQRCode:code width:weakSelf.qrCodeImageView.frame.size.width height:weakSelf.qrCodeImageView.frame.size.height];
            break;
        case 1:
            generateImage = [self generate128BarCode:code width:weakSelf.qrCodeImageView.frame.size.width height:weakSelf.qrCodeImageView.frame.size.height];
            break;
        case 2:
            generateImage = [self generateAztecCode:code width:weakSelf.qrCodeImageView.frame.size.width height:weakSelf.qrCodeImageView.frame.size.height];
            break;
        default:
            break;
    }
    
    if(generateImage == NULL)
    {
        [self alertAction:@"錯誤" alertMessage:@"此文字無法生成你要的圖片" actionWithTitle:@"OK"];

        weakSelf.qrCodeImageView.userInteractionEnabled = NO;
    }
    else
    {
        weakSelf.qrCodeImageView.userInteractionEnabled = YES;
    }
    
    weakSelf.qrCodeImageView.image = generateImage;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(conformSaveImageActionAlert)];
    tapRecognizer.numberOfTapsRequired = 2;
    [_qrCodeImageView addGestureRecognizer:tapRecognizer];
}

-(void)conformSaveImageActionAlert
{
    UIAlertController *urlAlertCtrl = [UIAlertController alertControllerWithTitle:nil
                                                                          message:@"儲存影像"
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
                                   [self saveQRCode];
                               }];

    [urlAlertCtrl addAction:cancelAction];
    [urlAlertCtrl addAction:okAction];
    [self presentViewController:urlAlertCtrl animated:YES completion:nil];
}

-(void)saveQRCode
{
    UIGraphicsBeginImageContext(CGSizeMake(_qrCodeImageView.frame.size.width, _qrCodeImageView.frame.size.height));
    [_qrCodeImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageWriteToSavedPhotosAlbum(viewImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if(error)
    {
        [self alertAction:@"錯誤" alertMessage:[error description] actionWithTitle:@"確定"];
    }else{
        [self alertAction:@"成功" alertMessage:@"影像已經儲存至相簿" actionWithTitle:@"確定"];
    }
}

- (void)initPickerViewMainViewParameter
{
    _myCodePickView = [[UIPickerView alloc]init];
    [_myCodePickView setDelegate:self];
    [_myCodePickView setDataSource:self];
    [_myCodePickView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    _myCodePickView.layer.borderColor = [UIColor blackColor].CGColor;
    _myCodePickView.layer.borderWidth = 2;
    [_myCodePickView selectRow:0 inComponent:0 animated:YES];
    
    pickerCodeTitleArray = [NSArray arrayWithObjects:
                            @"QRCode",
                            @"128Barcode",
                            @"AztecCode",nil];
}

#pragma mark - UIPickerViewDataSource and UIPickerViewDelegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    //result.text = [array objectAtIndex:row];
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    NSInteger retNumberOfComponents;
    retNumberOfComponents = 1;
    
    return retNumberOfComponents;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger retNumberOfRowsInComponent;
    retNumberOfRowsInComponent = [pickerCodeTitleArray count];
    return retNumberOfRowsInComponent;
}

- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *retTitleForRow;
    retTitleForRow = [pickerCodeTitleArray objectAtIndex:row];
    return retTitleForRow;
}

#pragma mark - 生成條形碼以及二维碼
// 参考文档
// https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html
-(UIImage *)generateQRCode:(NSString *)code width:(CGFloat)width height:(CGFloat)height
{
    CIImage *qrcodeImage;
    NSData *data = [code dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:@"H" forKey:@"inputCorrectionLevel"];
    qrcodeImage = [filter outputImage];
    
    CGFloat scaleX = width / qrcodeImage.extent.size.width;
    CGFloat scaleY = height / qrcodeImage.extent.size.height;
    CIImage *transformedImage = [qrcodeImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleY)];
    
    return [UIImage imageWithCIImage:transformedImage];
}

-(UIImage *)generate128BarCode:(NSString *)code width:(CGFloat)width height:(CGFloat)height
{
    CIImage *barcodeImage;
    NSData *data = [code dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    
    [filter setValue:data forKey:@"inputMessage"];
    barcodeImage = [filter outputImage];
    
    CGFloat scaleX = width / barcodeImage.extent.size.width;
    CGFloat scaleY = height / barcodeImage.extent.size.height;
    CIImage *transformedImage = [barcodeImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleY)];
    NSLog(@"%@", [UIImage imageWithCIImage:transformedImage]);
    return [UIImage imageWithCIImage:transformedImage];
}

-(UIImage *)generateAztecCode:(NSString *)code width:(CGFloat)width height:(CGFloat)height
{
    CIImage *barcodeImage;
    NSData *data = [code dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    CIFilter *filter = [CIFilter filterWithName:@"CIAztecCodeGenerator"];
    
    [filter setValue:data forKey:@"inputMessage"];
    barcodeImage = [filter outputImage];
    
    CGFloat scaleX = width / barcodeImage.extent.size.width;
    CGFloat scaleY = height / barcodeImage.extent.size.height;
    CIImage *transformedImage = [barcodeImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleY)];
    
    return [UIImage imageWithCIImage:transformedImage];
}

-(UIImage *)generateCIPdf417Code:(NSString *)code width:(CGFloat)width height:(CGFloat)height
{
    CIImage *barcodeImage;
    NSData *data = [code dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    CIFilter *filter = [CIFilter filterWithName:@"CIPdf417Barcode"];
    
    [filter setValue:data forKey:@"inputMessage"];
    barcodeImage = [filter outputImage];
    
    CGFloat scaleX = width / barcodeImage.extent.size.width;
    CGFloat scaleY = height / barcodeImage.extent.size.height;
    CIImage *transformedImage = [barcodeImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleY)];
    
    return [UIImage imageWithCIImage:transformedImage];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"string:%@", [textField text]);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_inputTextField resignFirstResponder];
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
