//
//  TactileSlider+UIPointerInteractionDelegate.swift
//  TactileSlider
//
//  Created by Dale Price on 5/1/20.
//

import Foundation
import UIKit

@available(iOS 13.4, *)
extension TactileSlider: UIPointerInteractionDelegate {
	
	internal func setUpPointerInteraction() {
		let pointerInteraction = UIPointerInteraction(delegate: self)
		self.addInteraction(pointerInteraction)
	}
	
	public func targetedPreview(for interaction: UIPointerInteraction) -> UITargetedPreview? {
		if let interactionView = interaction.view {
			let previewParameters = UIPreviewParameters()
			previewParameters.visiblePath = UIBezierPath(roundedRect: bounds, cornerRadius: automaticCornerRadius)
			previewParameters.backgroundColor = .clear
			
			return UITargetedPreview(view: interactionView, parameters: previewParameters)
		}
		
		return nil
	}
	
	/// override this to set a custom pointer interaction style
	open func pointerStyle(with targetedPreview: UITargetedPreview) -> UIPointerStyle {
		return UIPointerStyle(
			effect: UIPointerEffect.hover(
        targetedPreview,
        preferredTintMode: UIPointerEffect.TintMode.overlay,
        prefersShadow: false,
        prefersScaledContent: true
      )
		)
	}
	
	open func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
		return UIPointerRegion(rect: self.bounds)
	}
	
	open func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
		var style: UIPointerStyle? = nil
		
		if isPointerInteractionEnabled {
			if let targetedPreview = targetedPreview(for: interaction) {
				style = pointerStyle(with: targetedPreview)
			}
		}
		return style
	}
}
