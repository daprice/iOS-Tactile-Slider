//
//  TactileSliderLayerRenderer.swift
//  TactileSlider
//
//  Created by Dale Price on 1/26/19.
//

import UIKit

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
	
	let trackLayer = CALayer()
	let thumbLayer = CAShapeLayer()
	let maskLayer = CAShapeLayer()
	let outlineLayer = CAShapeLayer()
	let thumbOutlineLayer = CAShapeLayer()
	
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
		
		updateOutlineLayer(updateBounds: false)
		updateOutlineColors()
	}
	
	internal func setupLayers() {
		trackLayer.addSublayer(thumbLayer)
		trackLayer.addSublayer(outlineLayer)
		thumbLayer.addSublayer(thumbOutlineLayer)
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
			color = slider.outlineColorProvider(slider)?.cgColor
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
}
