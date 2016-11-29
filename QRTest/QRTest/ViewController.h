//
//  ViewController.h
//  QRTest
//
//  Created by Jr2000 on 2016/9/29.
//  Copyright © 2016年 Jr2000. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewPreview;
@property (weak, nonatomic) IBOutlet UILabel *lblCodeType;
@property (weak, nonatomic) IBOutlet UITextField *lblStatusTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bbitemStart;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bbCopyText;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bbFromAlbum;


@end

