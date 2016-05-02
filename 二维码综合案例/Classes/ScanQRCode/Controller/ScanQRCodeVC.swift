//
//  ScanQRCodeVC.swift
//  二维码综合案例
//
//  Created by One'J on 16/4/28.
//  Copyright © 2016年 One'J. All rights reserved.
//

import UIKit
import AVFoundation

class ScanQRCodeVC: UIViewController {
    @IBOutlet weak var scanBackView: UIView!
    @IBOutlet weak var chongjiboImageView: UIImageView!
    @IBOutlet weak var toBottom: NSLayoutConstraint!
    
    
 
    
    weak var layer: AVCaptureVideoPreviewLayer?
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        startScanAnimation()
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        removeScanAnimation()
        startScan()
    }
    
    
    
    func startScan() -> () {
        
        QRCodeTool.shareInstance.setRectInterest(scanBackView.frame)
        
        QRCodeTool.shareInstance.scanQRCode(view, isDrawFrame: true) { (resultStrs) in
             print(resultStrs)
        }
      
    }
    
    
}




extension ScanQRCodeVC {
    
    
    func startScanAnimation() -> () {
        
        toBottom.constant = scanBackView.frame.size.height
        view.layoutIfNeeded()
        
        toBottom.constant = -scanBackView.frame.size.height
        
        UIView.animateWithDuration(1) {
            UIView.setAnimationRepeatCount(MAXFLOAT)
            self.view.layoutIfNeeded()
        }
    }
    
    
    func removeScanAnimation() {
        
        chongjiboImageView.layer.removeAllAnimations()

   
    }
    
    
}
