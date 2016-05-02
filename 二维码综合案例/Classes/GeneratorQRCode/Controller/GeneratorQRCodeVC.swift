//
//  GeneratorQRCodeVC.swift
//  二维码综合案例
//
//  Created by One'J on 16/4/28.
//  Copyright © 2016年 One'J. All rights reserved.
//

import UIKit
import CoreImage

class GeneratorQRCodeVC: UIViewController {

    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    
    @IBOutlet weak var inputTV: UITextView!
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        view.endEditing(true)
        
        
        let str = inputTV.text ?? ""
        let centerImage = UIImage(named: "erha.png")
        let image = QRCodeTool.generatorQRCode(str, centerImage: centerImage)
        
        qrCodeImageView.image = image

        
        
        
        
    }
    
    
       
    
    
}
