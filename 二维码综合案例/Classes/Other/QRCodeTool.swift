//
//  QRCodeTool.swift
//  二维码工具类
//
//  Created by One'J on 16/4/28.
//  Copyright © 2016年 One'J. All rights reserved.
//

import UIKit
import AVFoundation

typealias ScanResultBlock = ([String]) -> ()

class QRCodeTool: NSObject {
    
    static let shareInstance = QRCodeTool()
    
    /// 懒加载输入对象
    lazy var input: AVCaptureDeviceInput? = {
        // 1. 设置输入
        // 1.1 获取摄像头设备
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        // 1.2 把摄像头设备当做输入设备
        var input: AVCaptureDeviceInput?
        do {
            input = try AVCaptureDeviceInput(device: device)
            return input
        }catch {
            print(error)
            return nil
        }

    }()
    
    lazy var output: AVCaptureMetadataOutput = {
        // 2. 设置输出
        let output = AVCaptureMetadataOutput()
        // 2.1 设置结果处理的代理
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        return output
        
    }()
    
    lazy var session: AVCaptureSession = {
        // 3. 创建会话, 连接输入和输出
        let session = AVCaptureSession()
        return session

    }()
    
    lazy var layer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        return layer
        
    }()
    
    private var scanResultBlock: ScanResultBlock?
    private var isDrawFrame: Bool = false
    
    func scanQRCode(inView: UIView, isDrawFrame: Bool, resultBlock: (resultStrs: [String])->()) {
        
        // 记录闭包
        scanResultBlock = resultBlock
        self.isDrawFrame = isDrawFrame
        
        if session.canAddInput(input) && session.canAddOutput(output) {
            session.addInput(input)
            session.addOutput(output)
        }else {
            return
        }

        // 3.1 设置二维码可以识别的码制
        // 设置识别的类型, 必须要在输出添加到会话之后, 才可以设置, 不然, 崩溃
        // output.availableMetadataObjectTypes
        // AVMetadataObjectTypeQRCode
        output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        
        // 3.2 添加视频预览图层(让用户可以看到界面) (不是必须添加的)
        if inView.layer.sublayers == nil {
            layer.frame = inView.layer.bounds
            inView.layer.insertSublayer(layer, atIndex: 0)
        }else {
            let subLayers = inView.layer.sublayers!
            if  !subLayers.contains(layer) {
                layer.frame = inView.layer.bounds
                inView.layer.insertSublayer(layer, atIndex: 0)
            }
        }
    
        // 4. 启动会话, (让输入开始采集数据, 输出对象,开始处理数据)
        session.startRunning()
    }
    
    
    func setRectInterest(orignRect: CGRect) -> () {
        // 设置扫描 的兴趣区域
        //  CGRectMake(0, 0, 1, 1)  0.0 - 1.0
        // 0 0. 右上角
        let bounds = UIScreen.mainScreen().bounds
        let x: CGFloat = orignRect.origin.x / bounds.size.width
        let y: CGFloat = orignRect.origin.y / bounds.size.height
        let width: CGFloat = orignRect.size.width / bounds.size.width
        let height: CGFloat = orignRect.size.height / bounds.size.height
        output.rectOfInterest = CGRectMake(y, x, height, width)
    }
    
    

    // 探测图片
    // 参数1: 原始图片
    // 参数2: 是否需要绘制扫描边框
    // 返回值: 元组(结果字符串组成的数组, 绘制好二维码边框的图片(如果不要求绘制, 则返回的是原始图片))
    class func detectorQRCodeImage(image: UIImage, isDrawQRCodeFrame: Bool) -> (resultStrs: [String]?, resultImage: UIImage) {
        
        let imageCI = CIImage(image: image)
        
        // 开始识别
        // 1. 创建一个二维码探测器
        let dector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        // 2. 直接探测二维码特征
        let features = dector.featuresInImage(imageCI!)
        
        // 存储处理好的图片
        var resultImage = image
        
        var result = [String]()
        for feature in features {
            //            print(feature)
            let qrFeature = feature as! CIQRCodeFeature
            
            //            print(qrFeature.messageString)
            result.append(qrFeature.messageString)
            //            print(qrFeature.bounds)
            if isDrawQRCodeFrame {
                 resultImage = drawFrame(resultImage, feature: qrFeature)
            }
           
//            sourceImageView.image = resultImage
            
        }

        return (result, resultImage)
        
    }
    
    
    // 根据给定的字符串, 转换成为二维码图片, 并将结果返回
    // 参数1: 需要转换的字符串
    // 参数2: 二维码中间的自定义图片
    // 返回值: 生成后的结果图片
    // 优化: 可以将自定义图片, 单独写成一个方法也可以, 也可以暴露更多的参数出去, 让方法变得更加灵活, 比如说是中间图片的大小
    class func generatorQRCode(inputStr: String, centerImage: UIImage?) -> UIImage {
        
         // 1. 创建二维码滤镜
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        // 1.1 恢复滤镜默认设置
        filter?.setDefaults()
        
        // 2. 设置滤镜输入数据
        // KVC
        let data = inputStr.dataUsingEncoding(NSUTF8StringEncoding)
        filter?.setValue(data, forKey: "inputMessage")
        
        // 2.2 设置二维码的纠错率
        filter?.setValue("M", forKey: "inputCorrectionLevel")
        
        
        // 3. 从二维码滤镜里面, 获取结果图片
        var image = filter?.outputImage
        
        
        // 借助这个方法, 处理成为一个高清图片
        let transform = CGAffineTransformMakeScale(20, 20)
        image = image?.imageByApplyingTransform(transform)
        
        // 3.1 图片处理
        // (23.0, 23.0)
        var resultImage = UIImage(CIImage: image!)
//        print(resultImage.size)
        
        // 前景图片
//        let center = UIImage(named: "erha.png")
        if centerImage != nil {
            resultImage = getNewImage(resultImage, center: centerImage!)
        }
        
        
        // 4. 显示图片
        return resultImage
        
        
        
    }
    
    
 
}

/// 私有方法
/// 这些方法, 都是工具类内部, 自己使用, 并不是直接暴漏给外界, 这样的话, 最好使用private关键字修饰我们的方法
extension QRCodeTool {
    
    // 根据一个图片的特征, 以及图片, 来绘制边框
    class private func drawFrame(image: UIImage, feature: CIQRCodeFeature) -> UIImage {
        
        let size = image.size
        print(size)
        // 1. 开启图形上下文
        UIGraphicsBeginImageContext(size)
        
        
        // 2. 绘制大图片
        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
        
        // 转换坐标系(上下颠倒)
        let context = UIGraphicsGetCurrentContext()
        CGContextScaleCTM(context, 1, -1)
        CGContextTranslateCTM(context, 0, -size.height)
        
        // 3. 绘制路径
        let bounds = feature.bounds
        let path = UIBezierPath(rect: bounds)
        UIColor.redColor().setStroke()
        path.lineWidth = 6
        path.stroke()
        
        // 4. 取出结果图片
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // 5. 关闭上下文
        UIGraphicsEndImageContext()
        
        
        // 6. 返回结果
        return resultImage
        
  
    }
    
    
    // 根据给定的两个图片, 生成合成后的图片, 返回给外界
    class private func getNewImage(sourceImage: UIImage, center: UIImage) -> UIImage {
        
        let size = sourceImage.size
        // 1. 开启图形上下文
        UIGraphicsBeginImageContext(size)
        
        // 2. 绘制大图片
        sourceImage.drawInRect(CGRectMake(0, 0, size.width, size.height))
        
        // 3. 绘制小图片
        let width: CGFloat = 80
        let height: CGFloat = 80
        let x: CGFloat = (size.width - width) * 0.5
        let y: CGFloat = (size.height - height) * 0.5
        center.drawInRect(CGRectMake(x, y, width, height))
        
        
        // 4. 取出结果图片
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // 5. 关闭上下文
        UIGraphicsEndImageContext()
        
        
        // 6. 返回结果
        return resultImage
        
        
        
    }

  
}


extension QRCodeTool:  AVCaptureMetadataOutputObjectsDelegate {
    // 扫描到结果之后调用
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        if isDrawFrame {
            removeFrameLayer()
        }
        
        
        //        print("test")
        
        //        print(metadataObjects)
        var resultStrs = [String]()
        for obj in metadataObjects {
            if obj.isKindOfClass(AVMetadataMachineReadableCodeObject)
            {
                
                // 转换成为, 二维码, 在预览图层上的真正坐标
                // qrCodeObj.corners 代表二维码的四个角, 但是, 需要借助视频预览 图层,转换成为,我们需要的可以用的坐标
                let resultObj = layer.transformedMetadataObjectForMetadataObject(obj as! AVMetadataObject)

                let qrCodeObj = resultObj as! AVMetadataMachineReadableCodeObject
                
                resultStrs.append(qrCodeObj.stringValue)
//                print(qrCodeObj.stringValue)
//                print(qrCodeObj.corners)
                if isDrawFrame {
                     drawFrame(qrCodeObj)
                }
               
            }
        }
        if scanResultBlock != nil {
            scanResultBlock!(resultStrs)
        }
        
    }
    
    
    
    
    func drawFrame(qrCodeObj: AVMetadataMachineReadableCodeObject) -> () {
        
        let corners = qrCodeObj.corners
        
        // 1. 借助一个图形层, 来绘制
        let shapLayer = CAShapeLayer()
        shapLayer.fillColor = UIColor.clearColor().CGColor
        shapLayer.strokeColor = UIColor.redColor().CGColor
        shapLayer.lineWidth = 6
        
        // 2. 根据四个点, 创建一个路径
        let path = UIBezierPath()
        var index = 0
        for corner in corners {
            
            let pointDic = corner as! CFDictionary
            var point = CGPointZero
            CGPointMakeWithDictionaryRepresentation(pointDic, &point)
            
            // 第一个点
            if index == 0 {
                path.moveToPoint(point)
            }else {
                path.addLineToPoint(point)
            }
            
            
            index += 1
        }
        
        path.closePath()
        
        
        // 3. 给图形图层的路径赋值, 代表, 图层展示怎样的形状
        shapLayer.path = path.CGPath
        
        
        
        // 4. 直接添加图形图层到需要展示的图层
        layer.addSublayer(shapLayer)
        
        
    }
    
    
    func  removeFrameLayer() -> () {
        guard let subLayers = layer.sublayers else {return}
        
        for subLayer in subLayers {
            if subLayer.isKindOfClass(CAShapeLayer)
            {
                subLayer.removeFromSuperlayer()
            }
        }
    }
    
}



