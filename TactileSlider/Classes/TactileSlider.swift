//
//  TactileSlider.swift
//  Easy-to-grab slider control inspired by Control Center and HomeKit.
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
	
	/// If true, the slider will move in the vertical direction; if false, horizontal.
	///
	/// - Note: Ensure that the dimensions/layout constraints on the control make sense for the orientation set here.
	///
	/// - SeeAlso: `reverseValueAxis`
	@IBInspectable open var vertical: Bool = false {
		didSet {
			updateLayerFrames()
		}
	}
	
	/// If false (default), the minimum value will be at the bottom or left of the slider, depending on `vertical`; if true, the minimum will be at the top or right.
	///
	/// - SeeAlso: `vertical`
	@IBInspectable open var reverseValueAxis: Bool = false {
		didSet {
			updateLayerFrames()
		}
	}
	
	/// The minimum value for the slider
	///
	/// - Note: If you set this to above `maximum` or `value`, those values will be changed to match
	@IBInspectable open var minimum: Float = 0 {
		didSet {
			if maximum < minimum { maximum = minimum }
			if value < minimum { value = minimum }
			renderer.setValue(value)
			updateAccessibility()
		}
	}
	
	/// The maximum value for the slider
	///
	/// - Note: If you set this to below `minimum` or `value`, those values will be changed to match
	@IBInspectable open var maximum: Float = 1 {
		didSet {
			if minimum > maximum { minimum = maximum }
			if value > maximum { value = maximum }
			renderer.setValue(value)
			updateAccessibility()
		}
	}
	
	/// The current (or starting) value for the slider
	@IBInspectable open private(set) var value: Float = 0.5 {
		didSet(oldValue) {
			if oldValue != value {
				if value < minimum { value = minimum }
				if value > maximum { value = maximum }
				updateAccessibility()
			}
		}
	}
	
	/// Size, in screen points, of the area in which the user's drags will be treated as if they are shorter, in order to make precise changes easier
	///
	/// This is intended for use cases where the user might want to adjust the value of the slider by very small, precise amounts. If `precisionRampUpDistance` is non-zero, the sensitivity for pan gestures will start out lower (i.e. higher precision; the value will change by less than the user moved their finger) and ramp up until the user has moved their finger by this distance, after which the precision will be 1:1.
	///
	/// - Note: A value no larger than 5 to 10 points (or 10% of the length of the slider, whichever is smaller) is recommended.
	///
	/// Setting this to `0` results in the same behavior as UISlider, where the value change exactly matches the user's finger movement.
	///
	/// - Warning: If this is larger than the size of the slider's bounds, it will be very difficult to make large adjustments to the slider's value.
	@IBInspectable open var precisionRampUpDistance: Float = 0
	
	/// If true, will send `valueChanged` actions at every point during a movement of the slider; if false, will only send when the user lifts their finger
	///
	/// - Important: Because `TactileSlider` is designed to represent the direct manipulation of a value by the user, setting `isContinuous` to `false` could lead to suboptimal user experience – the user may expect to be able to watch the value change in real time while manipulating the slider, not only when lifting their finger. Only set `isContinuous` to `false` when absolutely necessary.
	@IBInspectable open var isContinuous: Bool = true
	
	/// If true, a single tap anywhere in the slider will set it to that value
	///
	/// On iOS 9 or later, direct taps or indirect (trackpad or mouse) clicks can be specified using the `allowedTapTypes` property.
	///
	/// - Remark: Users may accidentally activate this feature while trying to make very small adjustments. If the intended use case involves making very small, precise adjustments with the slider, consider disabling this feature or restricting it to indirect touches only using `allowedTapTypes`.
	@IBInspectable open var enableTapping: Bool = true {
		didSet {
			setTapEnabled()
		}
	}
	
	/// An array of `UITouch.TouchType`s used to distinguish the type of touches for the `enableTapping` feature.
	///
	/// This is a wrapper around the [UITapGestureRecognizer](https://developer.apple.com/documentation/uikit/uigesturerecognizer)'s [allowedTouchTypes](https://developer.apple.com/documentation/uikit/uigesturerecognizer/1624223-allowedtouchtypes) property.
	///
	/// If `enableTapping` is `true`, this can be used to filter direct (e.g. finger) or indirect (e.g. trackpad) touches.
	///
	/// - Requires: `enableTapping == true`, otherwise no effect
	open var allowedTapTypes: [NSNumber] {
		get {
			return tapGestureRecognizer.allowedTouchTypes
		}
		set(newAllowedTapTypes) {
			tapGestureRecognizer.allowedTouchTypes = newAllowedTapTypes
		}
	}
	
	/// If true, the slider can be adjusted by scrolling with a pointing device (e.g. two-finger scrolling with a trackpad or scrolling a mouse wheel).
	///
	/// - Requires: iOS 13.4
	///
	///   This setting only affects iPadOS with a connected pointing device.
	@IBInspectable open var isScrollingEnabled: Bool = true {
		didSet {
			if #available(iOS 13.4, *) {
				setScrollingEnabled()
			}
		}
	}
	
	/// If true, the slider will display a hover effect as the pointer hovers over it.
	///
	/// Override the `pointerStyle(with:)` method to customize the effect.
	///
	/// - Note: Enabling this option is intended to communicate to the user that they can easily perform an action using the pointer. Enabling `isScrollingEnabled`, `enableTapping`, __and__ allowing at least indirect touches using `allowedTapTypes` is recommended if this option is enabled.
	///
	/// - Requires: iOS 13.4
	///
	///   This setting only affects iPadOS with a connected pointing device.
	@IBInspectable open var isPointerInteractionEnabled: Bool = false
	
	/// If true, the slider will animate its scale when it is being dragged
	///
	/// - Warning: Not recommended together with `isPointerInteractionEnabled = true`
	@IBInspectable open var scaleUpWhenInUse: Bool = false
	
	/// The color of the track the slider slides along
	///
	/// - Note: By default, this is set to `tertiarySystemFill`, which is intended for filling large shapes. Be sure to [choose an appropriate fill color](https://developer.apple.com/documentation/uikit/uicolor/ui_element_colors) for the size of the control.
	///
	/// - Important: On iOS versions prior to iOS 13 that do not support dynamic system colors, this defaults to `lightGray`.
	@IBInspectable open var trackBackground: UIColor = {
		if #available(iOS 13, *) {
			return .tertiarySystemFill
		} else {
			return .lightGray
		}
	}() {
		didSet {
			renderer.trackBackground = trackBackground
		}
	}
	
	/// The radius of the rounded corners of the slider
	///
	/// Note: If this is set to a negative value (or left as default in interface builder), the corner radius will be automatically determined from the size of the bounds
	@IBInspectable open var cornerRadius: CGFloat = -1 {
		didSet {
			if cornerRadius < 0 {
				renderer.cornerRadius = automaticCornerRadius
			} else {
				renderer.cornerRadius = cornerRadius
			}
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
			tintAdjustmentMode = isEnabled ? .automatic : .dimmed
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
	
	internal var automaticCornerRadius: CGFloat {
		if cornerRadius < 0 {
			return min(bounds.width, bounds.height) / 3.3
		} else {
			return cornerRadius
		}
	}
	
	private let renderer = TactileSliderLayerRenderer()
	
	private var dragGestureRecognizer: UIPanGestureRecognizer!
	private var tapGestureRecognizer: UITapGestureRecognizer!
	
	/// cumulative length of active pan gesture(s)
	private var accumulatedMovement: CGFloat = 0
	
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
	
	/// The `UIImpactFeedbackGenerator.FeedbackStyle` used for haptic feedback when the slider reaches either end of its track
	///
	/// - Important: Only available on iOS 10.0 or later
	///
	/// - Note: Defaults to `.light` if not set
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
		
		dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
		dragGestureRecognizer.cancelsTouchesInView = false
		addGestureRecognizer(dragGestureRecognizer)
		
		tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
		tapGestureRecognizer.numberOfTapsRequired = 1
		tapGestureRecognizer.numberOfTouchesRequired = 1
		tapGestureRecognizer.cancelsTouchesInView = false
		addGestureRecognizer(tapGestureRecognizer)
		
		setTapEnabled()
		if #available(iOS 13.4, *) {
			setScrollingEnabled()
			setUpPointerInteraction()
		}
		
		renderer.tactileSlider = self
		renderer.cornerRadius = automaticCornerRadius
		traitCollectionDidChange(nil)
		
		layer.backgroundColor = UIColor.clear.cgColor
		layer.isOpaque = false
		layer.addSublayer(renderer.trackLayer)
		renderer.trackLayer.addSublayer(renderer.thumbLayer)
		
		updateLayerFrames()
	}
	
	/// Sets the value of the slider.
	///
	/// - Parameter newValue: the value to set the slider to
	/// - Parameter animated: whether or not to perform an asynchronous visual animation of the slider transitioning to the new value
	///
	/// - Postcondition: If the value passed in is greater than `minimum` and less than `maximum`, the `value` of the slider will be set to that value, otherwise it will be capped to within that range.
	open func setValue(_ newValue: Float, animated: Bool) {
		value = min(maximum, max(minimum, newValue))
		renderer.setValue(value, animated: animated)
	}
	
	
	// MARK: - Accessibility
	
	override open func accessibilityDecrement() {
		value -= (maximum - minimum) / 10
		renderer.setValue(value, animated: true)
		sendActions(for: [.valueChanged, .primaryActionTriggered])
	}
	
	override open func accessibilityIncrement() {
		value += (maximum - minimum) / 10
		renderer.setValue(value, animated: true)
		sendActions(for: [.valueChanged, .primaryActionTriggered])
	}
	
	/// Returns a string containing the value of the slider as a percentage
	///
	/// - Parameter locale: The `Locale` to format the value for; defaults to `Locale.current`
	open func valueAsPercentage(locale: Locale = Locale.current) -> String? {
		let valueNumber = (value - minimum) / (maximum - minimum) as NSNumber
		let valueFormatter = NumberFormatter()
		valueFormatter.numberStyle = .percent
		valueFormatter.maximumFractionDigits = 0
		valueFormatter.locale = locale
		
		return valueFormatter.string(from: valueNumber)
	}
	
	private func updateAccessibility() {
		accessibilityValue = valueAsPercentage()
	}
	
	
	// MARK: - gesture handling
	
	private func setTapEnabled() {
		tapGestureRecognizer.isEnabled = enableTapping
	}
	
	@available(iOS 13.4, *)
	private func setScrollingEnabled() {
		if isScrollingEnabled {
			dragGestureRecognizer.allowedScrollTypesMask = UIScrollTypeMask.all
		} else {
			dragGestureRecognizer.allowedScrollTypesMask = []
		}
	}
	
	@objc func didPan(sender: UIPanGestureRecognizer) {
		let translationLengthAlongValueAxis = valueAxisFrom(sender.translation(in: self))
		
		accumulatedMovement += translationLengthAlongValueAxis
		
		let adjustedTranslationLength = adjustForPrecision(precisionRampUpDistance, incrementLength: translationLengthAlongValueAxis, totalLength: accumulatedMovement)
		let requestedValueChange = valueChangeForTranslation(length: adjustedTranslationLength)
		
		if value == minimum && requestedValueChange < 0 {
			// already hit minimum, don't change the value
		} else if value == maximum && requestedValueChange > 0 {
			// already hit maximum, don't change the value
		} else {
			let newValue = value + requestedValueChange
			setValue(newValue, animated: false) // `setValue` clamps the actual value between min and max
			
			// control feedback generator according to state
			if #available(iOS 10.0, *) {
				switch sender.state {
				case .began:
					minMaxFeedbackGenerator = UIImpactFeedbackGenerator(style: feedbackStyle)
					minMaxFeedbackGenerator?.prepare()
				case .changed:
					if newValue != value { // if the requested value is outside min...max, these won't be equal
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
		}
		
		if isContinuous || sender.state == .ended || sender.state == .cancelled {
			sendActions(for: [.valueChanged, .primaryActionTriggered])
		}
		
		if sender.state != .ended && sender.state != .cancelled && sender.state != .failed {
			renderer.popUp = scaleUpWhenInUse
		} else {
			renderer.popUp = false
			accumulatedMovement = 0
		}
	}
	
	@objc func didTap(sender: UITapGestureRecognizer) {
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
			sendActions(for: [.valueChanged, .primaryActionTriggered])
		}
	}
	
	
	// MARK: - Graphics
	
	open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		renderer.trackBackground = trackBackground
		tintColorDidChange()
	}
	
	open override func tintColorDidChange() {
		renderer.thumbTint = tintColor
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		self.setNeedsDisplay()
	}
	
	override open func draw(_ rect: CGRect) {
		super.draw(rect)
		updateLayerFrames()
	}
	
	private func updateLayerFrames() {
		if cornerRadius < 0 {
			renderer.cornerRadius = automaticCornerRadius
		}
		renderer.updateBounds(bounds)
	}
	
	/// returns the position along the value axis for a given control value
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
	
	/// returns the control value for a given position along the value axis
	func valueForPosition(_ position: CGFloat) -> Float {
		switch direction {
		case .rightToLeft, .leftToRight:
			return Float(position) / Float(bounds.width) * (maximum - minimum) + minimum
		case .topToBottom, .bottomToTop:
			return Float(position) / Float(bounds.height) * (maximum - minimum) + minimum
		}
	}
	
	/// returns whichever axis in a Point represents the value axis for this particular slider
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
	
	func adjustForPrecision(_ rampUpDistance: Float, incrementLength: CGFloat, totalLength: CGFloat) -> CGFloat {
		if totalLength.magnitude < CGFloat(rampUpDistance) {
			let adjustmentRatio = totalLength.magnitude / CGFloat(rampUpDistance)
			return incrementLength * adjustmentRatio
		} else {
			return incrementLength
		}
	}
	
	func valueChangeForTranslation(length translationSizeAlongValueAxis: CGFloat) -> Float {
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
