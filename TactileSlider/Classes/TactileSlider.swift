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
	
	@IBInspectable open var minimum: Float = 0 {
		didSet {
			if maximum < minimum { maximum = minimum }
			if value < minimum { value = minimum }
			renderer.setValue(value)
			updateAccessibility()
		}
	}
	@IBInspectable open var maximum: Float = 1 {
		didSet {
			if minimum > maximum { minimum = maximum }
			if value > maximum { value = maximum }
			renderer.setValue(value)
			updateAccessibility()
		}
	}
	@IBInspectable open private(set) var value: Float = 0.5 {
		didSet(oldValue) {
			if oldValue != value {
				if value < minimum { value = minimum }
				if value > maximum { value = maximum }
				updateAccessibility()
			}
		}
	}
	
	@IBInspectable open var isContinuous: Bool = true
	
	// If true, a single tap anywhere in the slider will set it to that value
	@IBInspectable open var enableTapping: Bool = true
	
	// If true, the slider will animate its scale when it is being dragged
	@IBInspectable open var scaleUpWhenInUse: Bool = false
	
	@IBInspectable open var trackBackground: UIColor = UIColor.darkGray {
		didSet {
			renderer.trackBackground = trackBackground
		}
	}
	@IBInspectable open var thumbTint: UIColor = UIColor.white {
		didSet {
			renderer.thumbTint = thumbTint
		}
	}
	
	@IBInspectable var cornerRadius: CGFloat = 16 {
		didSet {
			renderer.cornerRadius = cornerRadius
		}
	}
	
	override open var frame: CGRect {
		didSet {
			updateLayerFrames()
		}
	}
	
	override open var isEnabled: Bool {
		didSet {
			renderer.grayedOut = !isEnabled
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
	
	private let renderer = TactileSliderLayerRenderer()
	
	// gross workaround for not being able to use @available on stored properties, from https://www.klundberg.com/blog/Swift-2-and-@available-properties/
	private var _minMaxFeedbackGenerator: AnyObject?
	@available(iOS 10.0, *) private var minMaxFeedbackGenerator: UIImpactFeedbackGenerator? {
		get {
			return _minMaxFeedbackGenerator as? UIImpactFeedbackGenerator
		}
		set(newValue) {
			_minMaxFeedbackGenerator = newValue
		}
	}
	
	private var _feedbackStyle: Int?
	@available(iOS 10.0, *) open var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
		get {
			guard let _feedbackStyle = _feedbackStyle,
				let style = UIImpactFeedbackGenerator.FeedbackStyle(rawValue: _feedbackStyle) else { return .light }
			return style
		}
		set(newValue) {
			_feedbackStyle = newValue.rawValue
		}
	}
	
	
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
		accessibilityTraits.insert(UIAccessibilityTraits.adjustable)
		
		let dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
		addGestureRecognizer(dragGestureRecognizer)
		
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
		tapGestureRecognizer.numberOfTapsRequired = 1
		tapGestureRecognizer.numberOfTouchesRequired = 1
		addGestureRecognizer(tapGestureRecognizer)
		
		renderer.tactileSlider = self
		renderer.cornerRadius = cornerRadius
		renderer.trackBackground = trackBackground
		renderer.thumbTint = thumbTint
		
		layer.backgroundColor = UIColor.clear.cgColor
		layer.isOpaque = false
		layer.addSublayer(renderer.trackLayer)
		renderer.trackLayer.addSublayer(renderer.thumbLayer)
		
		updateLayerFrames()
		
		if #available(iOS 10.0, *) {
			feedbackStyle = .light
		}
	}
	
	open func setValue(_ newValue: Float, animated: Bool) {
		value = min(maximum, max(minimum, newValue))
		renderer.setValue(value, animated: animated)
	}
	
	
	// MARK: - Accessibility
	
	override open func accessibilityDecrement() {
		value -= (maximum - minimum) / 10
		renderer.setValue(value, animated: true)
		sendActions(for: .valueChanged)
	}
	
	override open func accessibilityIncrement() {
		value += (maximum - minimum) / 10
		renderer.setValue(value, animated: true)
		sendActions(for: .valueChanged)
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
			setValue(newValue, animated: false)
			
			// control feedback generator according to state
			if #available(iOS 10.0, *) {
				switch sender.state {
				case .began:
					minMaxFeedbackGenerator = UIImpactFeedbackGenerator(style: feedbackStyle)
					minMaxFeedbackGenerator?.prepare()
				case .changed:
					if newValue != value {
						minMaxFeedbackGenerator?.impactOccurred()
						minMaxFeedbackGenerator?.prepare()
					}
				case .cancelled, .ended, .failed:
					_minMaxFeedbackGenerator = nil
				default:
					break
				}
			}
			
			let remainingTranslationAmount: CGFloat
			if value == newValue {
				remainingTranslationAmount = 0
			} else if (reverseValueAxis && !vertical) || (!reverseValueAxis && vertical) {
				remainingTranslationAmount = positionDifferenceForValueDifference(value - newValue)
			} else {
				remainingTranslationAmount = positionDifferenceForValueDifference(newValue - value)
			}
			sender.setTranslation(CGPoint(x: remainingTranslationAmount, y: remainingTranslationAmount), in: self)
			
			if isContinuous || sender.state == .ended || sender.state == .cancelled {
				sendActions(for: .valueChanged)
			}
			
			if sender.state != .ended && sender.state != .cancelled && sender.state != .failed {
				renderer.popUp = scaleUpWhenInUse
			} else {
				renderer.popUp = false
			}
		}
	}
	
	@objc func didTap(sender: UITapGestureRecognizer) {
		guard enableTapping else { return }
		
		if sender.state == .ended {
			let tapLocation: CGFloat
			if (reverseValueAxis && !vertical) || (!reverseValueAxis && vertical) {
				tapLocation = valueAxisFrom(CGPoint(x: bounds.width, y: bounds.height), accountForDirection: false) + valueAxisFrom(sender.location(in: self))
			}
			else {
				tapLocation = valueAxisFrom(sender.location(in: self), accountForDirection: false)
			}
			let tappedValue = valueForPosition(tapLocation)
			setValue(tappedValue, animated: true)
			sendActions(for: .valueChanged)
		}
	}
	
	
	// MARK: - Graphics
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		self.setNeedsDisplay()
	}
	
	override open func draw(_ rect: CGRect) {
		super.draw(rect)
		updateLayerFrames()
	}
	
	private func updateLayerFrames() {
		renderer.updateBounds(bounds)
	}
	
	// returns the position along the value axis for a given control value
	func positionForValue(_ value: Float) -> CGFloat {
		switch direction {
		case .rightToLeft, .leftToRight:
			return bounds.width * CGFloat((value - minimum) / (maximum - minimum))
		case .topToBottom, .bottomToTop:
			return bounds.height * CGFloat((value - minimum) / (maximum - minimum))
		}
	}
	
	func positionDifferenceForValueDifference(_ valueDifference: Float) -> CGFloat {
		switch direction {
		case .rightToLeft, .leftToRight:
			return bounds.width * CGFloat((valueDifference) / (maximum - minimum))
		case .topToBottom, .bottomToTop:
			return bounds.height * CGFloat((valueDifference) / (maximum - minimum))
		}
	}
	
	// returns the control value for a given position along the value axis
	func valueForPosition(_ position: CGFloat) -> Float {
		switch direction {
		case .rightToLeft, .leftToRight:
			return Float(position) / Float(bounds.width) * (maximum - minimum) + minimum
		case .topToBottom, .bottomToTop:
			return Float(position) / Float(bounds.height) * (maximum - minimum) + minimum
		}
	}
	
	// returns whichever axis in a Point represents the value axis for this particular slider
	func valueAxisFrom(_ point: CGPoint, accountForDirection: Bool = true) -> CGFloat {
		switch direction {
		case .leftToRight:
			return point.x
		case .rightToLeft:
			return accountForDirection ? -point.x : point.x
		case .bottomToTop:
			return accountForDirection ? -point.y : point.y
		case .topToBottom:
			return point.y
		}
	}
	
	func offAxisFrom(_ point: CGPoint, accountForDirection: Bool = true) -> CGFloat {
		switch direction {
		case .leftToRight:
			return point.y
		case .rightToLeft:
			return accountForDirection ? -point.y : point.y
		case .bottomToTop:
			return accountForDirection ? -point.x : point.x
		case .topToBottom:
			return point.x
		}
	}
	
	func valueChangeForTranslation(_ translation: CGPoint) -> Float {
		let translationSizeAlongValueAxis = valueAxisFrom(translation)
		let boundsSize = CGPoint(x: bounds.width, y: bounds.height)
		let boundsSizeAlongValueAxis = valueAxisFrom(boundsSize, accountForDirection: false)
		return Float(translationSizeAlongValueAxis / boundsSizeAlongValueAxis) * (maximum - minimum)
	}
	
	func pointOnSlider(valueAxisPosition: CGFloat, offAxisPosition: CGFloat) -> CGPoint {
		switch direction {
		case .leftToRight:
			return CGPoint(x: valueAxisPosition, y: offAxisPosition)
		case .rightToLeft:
			return CGPoint(x: bounds.width - valueAxisPosition, y: offAxisPosition)
		case .bottomToTop:
			return CGPoint(x: offAxisPosition, y: bounds.height - valueAxisPosition)
		case .topToBottom:
			return CGPoint(x: offAxisPosition, y: valueAxisPosition)
		}
	}
	
}
