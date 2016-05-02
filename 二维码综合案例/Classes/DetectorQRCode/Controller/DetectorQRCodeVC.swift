//
//  DetectorQRCodeVC.swift
//  二维码综合案例
//
//  Created by One'J on 16/4/28.
//  Copyright © 2016年 One'J. All rights reserved.
//

import UIKit

class DetectorQRCodeVC: UIViewController {

    
    @IBOutlet weak var sourceImageView: UIImageView!
    
    
    @IBAction func detectorQRCode() {
        
        
        // .1 获取需要识别的图片
        guard let image = sourceImageView.image else {return}
        
        
        let result = QRCodeTool.detectorQRCodeImage(image, isDrawQRCodeFrame: true)
        
        
        // 结果字符串
        let strs = result.resultStrs
        
        
        // 描绘好边框的图片
        sourceImageView.image = result.resultImage
        
        
        let alertVC = UIAlertController(title: "结果", message: strs?.description, preferredStyle: UIAlertControllerStyle.Alert)
        
        // 添加关闭行为
        let action = UIAlertAction(title: "关闭", style: UIAlertActionStyle.Default) { (action: UIAlertAction) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertVC.addAction(action)
        
        presentViewController(alertVC, animated: true, completion: nil)
        
        
        
        
    }
    

    
    
    
    
    
    
   
}
