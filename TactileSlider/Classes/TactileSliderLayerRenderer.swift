//
//  TactileSliderLayerRenderer.swift
//  TactileSlider
//
//  Created by Dale Price on 1/26/19.
//

import UIKit

@available(iOS 9, *)
@available(tvOS, unavailable)
@available(macOS, unavailable)
internal class TactileSliderLayerRenderer {
    
    private static var valueChangeTimingFunction = CAMediaTimingFunction(name: .default)
    
    weak var tactileSlider: TactileSlider?
    
    var trackBackground: UIColor = .darkGray {
        didSet {
            trackLayer.backgroundColor = trackBackground.cgColor
        }
    }
    
    var outlineSize: CGFloat = 1 {
        didSet {
            updateOutlineLayer()
        }
    }
    
    var thumbTint: UIColor = .white {
        didSet {
            thumbLayer.fillColor = thumbTint.cgColor
        }
    }
    
    var cornerRadius: CGFloat = 10 {
        didSet {
            updateMaskAndOutlineLayerPath()
        }
    }
    
    var grayedOut: Bool = false {
        didSet {
            updateGrayedOut()
        }
    }
    
    var popUp: Bool = false {
        didSet(oldValue) {
            if oldValue != popUp {
                updatePopUp()
            }
        }
    }
    
    var image:UIImage? = nil{
        didSet{
            updateImage()
        }
    }
    
    var imagePosition:TactileSlider.ImagePosition = .bottom{
        didSet{
            updateImageFrame()
        }
    }
    
    var imageSize:CGSize = .init(width: 20, height: 20){
        didSet{
            updateImageFrame()
        }
    }
    
    
    let trackLayer = CALayer()
    let thumbLayer = CAShapeLayer()
    let maskLayer = CAShapeLayer()
    let outlineLayer = CAShapeLayer()
    let thumbOutlineLayer = CAShapeLayer()
    let imageLayer = CALayer()
    
    init() {
        trackLayer.backgroundColor = trackBackground.cgColor
        thumbLayer.fillColor = thumbTint.cgColor
        thumbLayer.masksToBounds = true
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.backgroundColor = UIColor.clear.cgColor
        trackLayer.mask = maskLayer
        trackLayer.masksToBounds = true
        outlineLayer.backgroundColor = nil
        outlineLayer.fillColor = nil
        thumbOutlineLayer.backgroundColor = nil
        imageLayer.backgroundColor = nil
        
        updateOutlineLayer(updateBounds: false)
        updateOutlineColors()
        updateImage()
        updateImageFrame()
    }
    
    internal func setupLayers() {
        trackLayer.addSublayer(thumbLayer)
        trackLayer.addSublayer(outlineLayer)
        thumbLayer.addSublayer(thumbOutlineLayer)
        trackLayer.addSublayer(imageLayer)
    }
    
    private func updateThumbLayerPath() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        thumbLayer.path = CGPath(rect: CGRect(x: 0, y: 0, width: thumbLayer.bounds.width, height: thumbLayer.bounds.height), transform: nil)
        
        updateThumbOutlineLayerPath()
        
        CATransaction.commit()
    }
    
    private func updateThumbOutlineLayerPath() {
        guard let slider = tactileSlider else {
            return
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let edgeInsets: UIEdgeInsets
        switch (slider.vertical, slider.reverseValueAxis) {
        case (false, false):
            edgeInsets = UIEdgeInsets(top: 0, left: thumbLayer.bounds.width - outlineSize, bottom: 0, right: -1)
        case (false, true):
            edgeInsets = UIEdgeInsets(top: 0, left: -1, bottom: 0, right: thumbLayer.bounds.width - outlineSize)
        case (true, false):
            edgeInsets = UIEdgeInsets(top: -1, left: 0, bottom: thumbLayer.bounds.height - outlineSize, right: 0)
        case (true, true):
            edgeInsets = UIEdgeInsets(top: thumbLayer.bounds.height - outlineSize, left: 0, bottom: -1, right: 0)
        }
        
        let baseRect = CGRect(x: 0, y: 0, width: thumbLayer.bounds.width, height: thumbLayer.bounds.height)
        let insetRect = baseRect.inset(by: edgeInsets)
        thumbOutlineLayer.path = CGPath(rect: insetRect, transform: nil)
        
        CATransaction.commit()
    }
    
    private func updateMaskAndOutlineLayerPath() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let maskRect = CGRect(x: 0, y: 0, width: maskLayer.bounds.width, height: maskLayer.bounds.height)
        let maskPath = UIBezierPath(roundedRect: maskRect, cornerRadius: cornerRadius).cgPath
        maskLayer.path = maskPath
        outlineLayer.path = maskPath
        
        CATransaction.commit()
    }
    
    internal func updateOutlineColors() {
        let color: CGColor?
        if let slider = tactileSlider {
            color = slider.finalOutlineColor?.cgColor
        } else {
            color = nil
        }
        
        outlineLayer.strokeColor = color
        thumbOutlineLayer.fillColor = color
    }
    
    private func updateOutlineLayer(updateBounds: Bool = true) {
        outlineLayer.lineWidth = outlineSize * 2
        if updateBounds { updateThumbOutlineLayerPath() }
    }
    
    private func updateGrayedOut() {
        let alpha: Float = grayedOut ? 0.6 : 1
        trackLayer.opacity = alpha
    }
    
    private func updatePopUp() {
        CATransaction.begin()
        
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        CATransaction.setAnimationDuration(0.1)
        
        let zPosition: CGFloat = popUp ? 1.025 : 1
        trackLayer.transform = CATransform3DScale(CATransform3DIdentity, zPosition, zPosition, zPosition)
        
        CATransaction.commit()
    }
    
    internal func updateBounds(_ bounds: CGRect) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        trackLayer.bounds = bounds
        trackLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        maskLayer.bounds = trackLayer.bounds
        maskLayer.position = trackLayer.position
        outlineLayer.bounds = trackLayer.bounds
        outlineLayer.position = trackLayer.position
        updateMaskAndOutlineLayerPath()
        
        thumbLayer.bounds = trackLayer.bounds
        thumbLayer.position = trackLayer.position
        thumbOutlineLayer.bounds = trackLayer.bounds
        thumbOutlineLayer.position = trackLayer.position
        updateThumbLayerPath()
        
        updateImage()
        updateImageFrame()
        
        if let value = tactileSlider?.value {
            setValue(value)
        }
        
        CATransaction.commit()
    }
    
    internal func setValue(_ value: Float, animated: Bool = false) {
        CATransaction.begin()
        
        if animated {
            CATransaction.setAnimationTimingFunction(Self.valueChangeTimingFunction)
        } else {
            CATransaction.setDisableActions(true)
        }
        
        let valueAxisOffset = tactileSlider!.valueAxisFrom(CGPoint(x: thumbLayer.bounds.width, y: thumbLayer.bounds.height), accountForDirection: true)
        let valueAxisAmount = tactileSlider!.positionForValue(value)
        let reverseOffset = (tactileSlider!.reverseValueAxis && !tactileSlider!.vertical) || (!tactileSlider!.reverseValueAxis && tactileSlider!.vertical)
        let position = tactileSlider!.pointOnSlider(valueAxisPosition: valueAxisAmount - (reverseOffset ? 0 : valueAxisOffset), offAxisPosition: 0)
        
        thumbLayer.transform = CATransform3DTranslate(CATransform3DIdentity, position.x, position.y, 0)
        
        CATransaction.commit()
    }
    
    private func updateImage(){
        guard let image else {
            imageLayer.contents = nil
            return
        }
        
        imageLayer.contents = image.cgImage
    }
    
    private func updateImageFrame(){
        
        
        var origin:CGPoint = .zero
        switch imagePosition {
        case .left:
            let leftPadding = min(trackLayer.frame.maxX * 0.1, 30)
            origin = .init(x: trackLayer.frame.minX + leftPadding, y: trackLayer.frame.midY-imageSize.height/2)
        case .right:
            let rightPadding = min(trackLayer.frame.maxX * 0.1, 30)
            origin = .init(x: trackLayer.frame.maxX - imageSize.width - rightPadding, y: trackLayer.frame.midY-imageSize.height/2)
        case .top:
            let topPadding =  min(trackLayer.frame.maxY * 0.1, 30)
            origin = .init(x: trackLayer.frame.midX - imageSize.width/2, y: trackLayer.frame.minY+topPadding)
        case .bottom:
            let bottomPadding = min(trackLayer.frame.maxY * 0.1, 30)
            origin = .init(x: trackLayer.frame.midX - imageSize.width/2, y: trackLayer.frame.maxY-imageSize.height - bottomPadding)
        case .center:
            origin = .init(x: trackLayer.frame.midX - imageSize.width/2, y: trackLayer.frame.midY-imageSize.height/2)
        }
        
        
        imageLayer.frame = .init(origin: origin, size: imageSize)
        imageLayer.contentsGravity = .resizeAspect
        imageLayer.isGeometryFlipped = true
    }
}

extension UIImage {

    func maskWithColor(color: UIColor) -> UIImage? {
        let maskImage = cgImage!

        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!

        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)

        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }

}
