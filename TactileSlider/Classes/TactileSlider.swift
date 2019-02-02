//
//  TactileSlider.swift
//  Pods
//
//  Created by Dale Price on 1/22/19.
//

import UIKit

@IBDesignable open class TactileSlider: UIControl {
	
	private enum Direction {
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
	
	@IBInspectable open var vertical: Bool = false {
		didSet {
			updateLayerFrames()
		}
	}
	
	@IBInspectable open var reverseValueAxis: Bool = false {
		didSet {
			updateLayerFrames()
		}
	}
	
	@IBInspectable open var value: Double = 0.5 {
		didSet(oldValue) {
			if oldValue != value {
				if value < minimum { value = minimum }
				if value > maximum { value = maximum }
				updateLayerFrames()
			}
		}
	}
	@IBInspectable open var minimum: Double = 0 {
		didSet {
			if maximum < minimum { maximum = minimum }
			if value < minimum { value = minimum }
			updateLayerFrames()
		}
	}
	@IBInspectable open var maximum: Double = 1 {
		didSet {
			if minimum > maximum { minimum = maximum }
			if value > maximum { value = maximum }
			updateLayerFrames()
		}
	}
	
	@IBInspectable open var enableTapping: Bool = true
	
	@IBInspectable open var trackTint: UIColor = UIColor(white: 0.2, alpha: 1) {
		didSet {
			updateLayerFrames()
		}
	}
	@IBInspectable open var trackHighlight: UIColor = UIColor(white: 1, alpha: 1) {
		didSet {
			updateLayerFrames()
		}
	}
	
	@IBInspectable var cornerRadius: CGFloat = 10 {
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
	
	private var direction: Direction {
		switch (vertical, reverseValueAxis) {
		case (false, false):
			return .leftToRight
		case (false, true):
			return .rightToLeft
		case (true, false):
			return .bottomToTop
		case (true, true):
			return .topToBottom
		}
	}
	
	private let trackLayer = TactileSliderTrackLayer()
	
	
	// MARK: - Initialization
	
	override public init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
	
	private func setup() {
		isAccessibilityElement = true
		accessibilityTraits += UIAccessibilityTraitAdjustable
		
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
	
	
	// MARK: - Accessibility
	
	override open func accessibilityDecrement() {
		value -= (maximum - minimum) / 10
	}
	
	override open func accessibilityIncrement() {
		value += (maximum - minimum) / 10
	}
	
	public func valueAsPercentage(locale: Locale = Locale.current) -> String? {
		let valueNumber = (value - minimum) / (maximum - minimum) as NSNumber
		let valueFormatter = NumberFormatter()
		valueFormatter.numberStyle = .percent
		valueFormatter.maximumFractionDigits = 0
		valueFormatter.locale = locale
		
		return valueFormatter.string(from: valueNumber)
	}
	
	open func updateAccessibility() {
		accessibilityValue = valueAsPercentage()
	}
	
	
	// MARK: - gesture handling
	
	@objc func didPan(sender: UIPanGestureRecognizer) {
		let translation = sender.translation(in: self)
		let valueChange = valueChangeForTranslation(translation)
		
		if value == minimum && valueChange < 0 {
			// already hit minimum, don't change the value
		} else if value == maximum && valueChange > 0 {
			// already hit maximum, don't change the value
		} else {
			let newValue = value + valueChange
			value = min(max(newValue, minimum), maximum)
			
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
		
		layer.cornerRadius = cornerRadius
		layer.masksToBounds = cornerRadius > 0
		
		trackLayer.frame = bounds
		trackLayer.setNeedsDisplay()
		
		CATransaction.commit()
		
		updateAccessibility()
	}
	
	// returns the position along the value axis for a given control value
	func positionForValue(_ value: Double) -> CGFloat {
		switch direction {
		case .rightToLeft, .leftToRight:
			return bounds.width * CGFloat((value - minimum) / (maximum - minimum))
		case .topToBottom, .bottomToTop:
			return bounds.height * CGFloat((value - minimum) / (maximum - minimum))
		}
	}
	
	// returns the control value for a given position along the value axis
	func valueForPosition(_ position: CGFloat) -> Double {
		switch direction {
		case .rightToLeft, .leftToRight:
			return Double(position) / Double(bounds.width) * (maximum - minimum) + minimum
		case .topToBottom, .bottomToTop:
			return Double(position) / Double(bounds.height) * (maximum - minimum) + minimum
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
		let translationSizeAlongValueAxis = valueAxisFrom(translation, accountForDirection: false)
		let boundsSize = CGPoint(x: bounds.width, y: bounds.height)
		let boundsSizeAlongValueAxis = valueAxisFrom(boundsSize)
		return Double(translationSizeAlongValueAxis / boundsSizeAlongValueAxis) * (maximum - minimum)
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
