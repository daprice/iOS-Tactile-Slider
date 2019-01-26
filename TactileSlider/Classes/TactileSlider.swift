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
		
		fileprivate var subtractive: Bool {
			get {
				switch self {
				case .bottomToTop, .leftToRight:
					return true
				default:
					return false
				}
			}
		}
	}

	// MARK: - Public properties
	
	open var direction: Direction = .rightToLeft {
		didSet {
			updateLayerFrames()
		}
	}
	
	@IBInspectable open var minimumValue: Double = 0 {
		didSet {
			if maximumValue < minimumValue { maximumValue = minimumValue }
			if value < minimumValue { value = minimumValue }
			updateLayerFrames()
		}
	}
	@IBInspectable open var maximumValue: Double = 1 {
		didSet {
			if minimumValue > maximumValue { minimumValue = maximumValue }
			if value > maximumValue { value = maximumValue }
			updateLayerFrames()
		}
	}
	@IBInspectable open var value: Double = 0.5 {
		didSet(oldValue) {
			if oldValue != value {
				if value < minimumValue { value = minimumValue }
				if value > maximumValue { value = maximumValue }
				updateLayerFrames()
			}
		}
	}
	
	@IBInspectable open var enableTapping: Bool = true
	
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

	override open var isEnabled: Bool {
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
		
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
		tapGestureRecognizer.numberOfTapsRequired = 1
		tapGestureRecognizer.numberOfTouchesRequired = 1
		addGestureRecognizer(tapGestureRecognizer)
		
		trackLayer.tactileSlider = self
		trackLayer.contentsScale = UIScreen.main.scale
		layer.addSublayer(trackLayer)
		
		updateLayerFrames()
	}
	
	// MARK: - gesture handling
	
	@objc func didPan(sender: UIPanGestureRecognizer) {
		let translation = sender.translation(in: self)
		let valueChange = valueChangeForTranslation(translation)
		
		if value == minimumValue && valueChange < 0 {
			// already hit minimum, don't change the value
		} else if value == maximumValue && valueChange > 0 {
			// already hit maximum, don't change the value
		} else {
			let newValue = value + valueChange
			value = min(max(newValue, minimumValue), maximumValue)
			
			let remainingTranslationAmount: CGFloat
			if value == newValue {
				remainingTranslationAmount = 0
			} else if direction.subtractive {
				remainingTranslationAmount = positionForValue(value - newValue)
			} else {
				remainingTranslationAmount = positionForValue(newValue - value)
			}
			sender.setTranslation(CGPoint(x: remainingTranslationAmount, y: remainingTranslationAmount), in: self)
			
			sendActions(for: .valueChanged)
		}
	}
	
	@objc func didTap(sender: UITapGestureRecognizer) {
		guard enableTapping else { return }
		
		if sender.state == .ended {
			let tapLocation: CGFloat
			if direction.subtractive {
				tapLocation = valueAxisFrom(CGPoint(x: bounds.width, y: bounds.height), accountForDirection: false) + valueAxisFrom(sender.location(in: self))
			}
			else {
				tapLocation = valueAxisFrom(sender.location(in: self), accountForDirection: false)
			}
			let tappedValue = valueForPosition(tapLocation)
			value = tappedValue
			sendActions(for: .valueChanged)
		}
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
	
	// returns the control value for a given position along the value axis
	func valueForPosition(_ position: CGFloat) -> Double {
		switch direction {
		case .rightToLeft, .leftToRight:
			return Double(position) / Double(bounds.width) * (maximumValue - minimumValue) + minimumValue
		case .topToBottom, .bottomToTop:
			return Double(position) / Double(bounds.height) * (maximumValue - minimumValue) + minimumValue
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
