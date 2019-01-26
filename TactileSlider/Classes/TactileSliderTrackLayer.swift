//
//  TactileSliderTrackLayer.swift
//  TactileSlider
//
//  Created by Dale Price on 1/26/19.
//

import UIKit

class TactileSliderTrackLayer: CALayer {
	
	weak var tactileSlider: TactileSlider?
	
	override func draw(in ctx: CGContext) {
		guard let tactileSlider = tactileSlider else {
			return
		}
		
		let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
		ctx.addPath(path.cgPath)
		
		// fill the background of the track
		ctx.setFillColor(tactileSlider.trackTintColor.cgColor)
		ctx.fillPath()
		
		// fill the slider portion of the track
		ctx.setFillColor(tactileSlider.trackHighlightTintColor.cgColor)
		
		let zeroPosition = tactileSlider.positionForValue(tactileSlider.minimumValue)
		let valuePosition = tactileSlider.positionForValue(tactileSlider.value)
		let rectOrigin = tactileSlider.pointOnSlider(valueAxisPosition: zeroPosition, offAxisPosition: 0)
		let rectDimensions = tactileSlider.pointOnSlider(valueAxisPosition: valuePosition, offAxisPosition: bounds.height)
		let rect = CGRect(x: min(rectOrigin.x, rectDimensions.x),
						  y: min(rectOrigin.y, rectDimensions.y),
						  width: max(rectDimensions.x, rectOrigin.x),
						  height: max(rectDimensions.y, rectOrigin.y))
		ctx.fill(rect)
	}
	
}
