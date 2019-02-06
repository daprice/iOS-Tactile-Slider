//
//  TactileSliderLayerRenderer.swift
//  TactileSlider
//
//  Created by Dale Price on 1/26/19.
//

import UIKit

internal class TactileSliderLayerRenderer {
	
	weak var tactileSlider: TactileSlider?
	
	var trackBackground: UIColor = .darkGray {
		didSet {
			trackLayer.backgroundColor = trackBackground.cgColor
		}
	}
	
	var thumbTint: UIColor = .white {
		didSet {
			thumbLayer.fillColor = thumbTint.cgColor
		}
	}
	
	var cornerRadius: CGFloat = 10 {
		didSet {
			updateMaskLayerPath()
		}
	}
	
	let trackLayer = CALayer()
	let thumbLayer = CAShapeLayer()
	let maskLayer = CAShapeLayer()
	
	init() {
		trackLayer.backgroundColor = trackBackground.cgColor
		thumbLayer.fillColor = thumbTint.cgColor
		maskLayer.fillColor = UIColor.white.cgColor
		maskLayer.backgroundColor = UIColor.black.cgColor
		trackLayer.mask = maskLayer
		trackLayer.masksToBounds = true
	}
	
	private func updateThumbLayerPath() {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		thumbLayer.path = CGPath(rect: CGRect(x: 0, y: 0, width: thumbLayer.bounds.width, height: thumbLayer.bounds.height), transform: nil)
		
		CATransaction.commit()
	}
	
	private func updateMaskLayerPath() {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		let maskRect = CGRect(x: 0, y: 0, width: maskLayer.bounds.width, height: maskLayer.bounds.height)
		maskLayer.path = CGPath(roundedRect: maskRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
		
		CATransaction.commit()
	}
	
	internal func updateBounds(_ bounds: CGRect) {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		trackLayer.bounds = bounds
		trackLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
		
		maskLayer.bounds = bounds
		maskLayer.position = trackLayer.position
		
		thumbLayer.bounds = trackLayer.bounds
		thumbLayer.position = trackLayer.position
		updateThumbLayerPath()
		
		CATransaction.commit()
		
		if let value = tactileSlider?.value {
			showValue(value)
		}
	}
	
	internal func showValue(_ value: Float) {
		let valueAxisOffset = tactileSlider!.valueAxisFrom(CGPoint(x: thumbLayer.bounds.width, y: thumbLayer.bounds.height), accountForDirection: true)
		let valueAxisAmount = tactileSlider!.positionForValue(value)
		let position = tactileSlider!.pointOnSlider(valueAxisPosition: valueAxisAmount - (tactileSlider!.reverseValueAxis ? 0 : valueAxisOffset), offAxisPosition: 0)
		
		thumbLayer.transform = CATransform3DTranslate(CATransform3DIdentity, position.x, position.y, 0)
	}
}
