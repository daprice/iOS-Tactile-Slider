//
//  TactileSlider.swift
//  Pods
//
//  Created by Dale Price on 1/22/19.
//

import UIKit

@IBDesignable open class TactileSlider: UIControl {
	
	public enum Direction {
		case rightToLeft
		case leftToRight
		case topToBottom
		case bottomToTop
	}

	// MARK: - Public properties
	
	open var direction: Direction = .rightToLeft {
		didSet {
			updateLayerFrames()
		}
	}
	
	@IBInspectable open var minimumValue: Double = 0 {
		didSet {
			updateLayerFrames()
		}
	}
	@IBInspectable open var maximumValue: Double = 1 {
		didSet {
			updateLayerFrames()
		}
	}
	@IBInspectable open var value: Double = 0.5 {
		// TODO: make sure it stays within minimum and maximum value
		didSet {
			updateLayerFrames()
		}
	}
	
	@IBInspectable open var trackTintColor = UIColor(white: 0.2, alpha: 1) {
		didSet {
			updateLayerFrames()
		}
	}
	@IBInspectable open var trackHighlightTintColor = UIColor(white: 1, alpha: 1) {
		didSet {
			updateLayerFrames()
		}
	}
	
	override open var frame: CGRect {
		didSet {
			updateLayerFrames()
		}
	}
	
	// MARK: - Private properties
	
	private let trackLayer = TactileSliderTrackLayer()
	
	override public init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		let dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
		addGestureRecognizer(dragGestureRecognizer)
		// TODO: tap gesture recognizer (optional)
		
		trackLayer.tactileSlider = self
		trackLayer.contentsScale = UIScreen.main.scale
		layer.addSublayer(trackLayer)
		
		updateLayerFrames()
	}
	
	// MARK: - gesture handling
	
	@objc func didPan(panRecognizer: UIPanGestureRecognizer) {
		let translation = panRecognizer.translation(in: self)
		value += valueChangeForTranslation(translation)
		
		panRecognizer.setTranslation(CGPoint.zero, in: self)
	}
	
	
	// MARK: - Graphics
	
	override open func draw(_ rect: CGRect) {
		super.draw(rect)
		updateLayerFrames()
	}
	
	private func updateLayerFrames() {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		trackLayer.frame = bounds
		trackLayer.setNeedsDisplay()
		
		CATransaction.commit()
	}
	
	// returns the position along the value axis for a given control value
	func positionForValue(_ value: Double) -> CGFloat {
		switch direction {
		case .rightToLeft, .leftToRight:
			return bounds.width * CGFloat((value - minimumValue) / (maximumValue - minimumValue))
		case .topToBottom, .bottomToTop:
			return bounds.height * CGFloat((value - minimumValue) / (maximumValue - minimumValue))
		}
	}
	
	func valueAxisFrom(_ point: CGPoint, accountForDirection: Bool = true) -> CGFloat {
		switch direction {
		case .rightToLeft:
			return point.x
		case .leftToRight:
			return accountForDirection ? -point.x : point.x
		case .bottomToTop:
			return accountForDirection ? -point.y : point.y
		case .topToBottom:
			return point.y
		}
	}
	
	func valueChangeForTranslation(_ translation: CGPoint) -> Double {
		let translationSize = valueAxisFrom(translation, accountForDirection: false)
		let boundsSize = CGPoint(x: bounds.width, y: bounds.height)
		let boundsSizeAlongValueAxis = valueAxisFrom(boundsSize)
		return Double(translationSize / boundsSizeAlongValueAxis) * (maximumValue - minimumValue)
	}
	
	func pointOnSlider(valueAxisPosition: CGFloat, offAxisPosition: CGFloat) -> CGPoint {
		switch direction {
		case .rightToLeft:
			return CGPoint(x: valueAxisPosition, y: offAxisPosition)
		case .leftToRight:
			return CGPoint(x: bounds.width - valueAxisPosition, y: offAxisPosition)
		case .bottomToTop:
			return CGPoint(x: offAxisPosition, y: bounds.height - valueAxisPosition)
		case .topToBottom:
			return CGPoint(x: offAxisPosition, y: valueAxisPosition)
		}
	}
	
}
