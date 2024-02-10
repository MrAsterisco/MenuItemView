#if canImport(AppKit)
import AppKit

/// A view that replicates the behavior of a menu item and
/// can be used to wrap custom views assigned to an `NSMenuItem`.
///
/// # Overview
/// This view is designed to be used as the `view` property of an `NSMenuItem`.
/// By default, the view is empty: you can design your own content and add it as subview
/// of a `MenuItemView` instance to automatically get menu-like behaviors such as
/// selection, highlighting, and flashing animations when clicked.
///
/// The general use-case is that you pass a custom view to ``addSubview(_:layoutAutomatically:)``
/// and let the `MenuItemView` handle everything.
///
/// ```swift
/// let customView = { /* Build your view */ }()
/// let menuItemView = MenuItemView()
/// menuItemView.addSubview(customView, layoutAutomatically: true)
///
/// // When you're ready to assign the view to a `NSMenuItem`.
/// menuItem.view = menuItemView
/// ```
///
/// # Content
/// You are expected to add your own content as subviews. While you can
/// build complex layouts, the simplest use case is covered by the convenience
/// function ``addSubview(_:layoutAutomatically:)``.
///
/// This function adds the passed view to the subviews and the required
/// constraints so that it matches the size of the menu item according to the `layoutMarginsGuide`.
/// This ensures that the view is laid out with some margins from the highlight
/// area.
///
/// - note: Using this function will also turn off `translatesAutoresizingMaskIntoConstraints`
/// for the menu item view and the passed view.
///
/// ## Adding Content Manually
///
/// If you'd like to add your subviews manually, you can invoke `addSubview`
/// as any other `NSView` subclass. However, when setting up constraints, make sure
/// to use the `layoutMarginsGuide` anchors.
/// 
/// If you are not using AutoLayout, use the ``contentMargins`` or the ``highlightMargins``
/// to align your views correctly.
///
/// # Highlighting
/// By default, when assigning a `view` to an `NSMenuItem`, the view
/// is not highlighted as any other normal item in menus. This view solves this
/// by automatically showing an highlighted view behind your content when
/// the enclosing menu item is highlighted.
///
/// - note: Highlighting is not applied when the enclosing menu item is disabled.
/// If your item is inside a menu that has `autoenablesItems` set to `true`, the item
/// will be disabled when there is no action associated to it.
///
/// ## Subviews
/// Some subviews can react automatically to the enclosing menu item's
/// highlighting state.
///
/// If ``autoHighlightSubviews`` is set to `true` (default), supported
/// views will automatically change their appearance to match the highlighted state.
///
/// When a a view is highlighted, it will be set to `NSColor.selectedMenuItemTextColor`,
/// whereas when it is not highlighted, it will default to `NSColor.controlTextColor`.
/// If the enclosing menu item is disabled, the appearance will be set to `NSColor.disabledControlTextColor`.
///
/// This behavior is supported, at the moment, for `NSTextField` and `NSImageView` instances.
///
/// - note: You can implement support for additional views, such as your own custom views, by subclassing
/// `MenuItemView` and overriding ``highlightIfNeeded(_:isHighlighted:isEnabled:)``.
///
/// - warning: The automatic highlighting of subviews changes the appearance of views directly.
/// If you don't want the view to change at all, make sure you set the property to `false` **before**
/// the menu item is displayed. If the item is highlighted even once before the property is turned off,
/// your custom colors will be overridden by the automatic highlighting.
///
/// ## Click Animation
/// When a menu item is selected with a click or tap, it blinks to confirm to the
/// user that the action was triggered. This view replicates this behavior
/// by means of a sequence of animations that quickly change the opacity of
/// the ``highlightView``.
///
/// Although it looks similar to what the `NSMenuItem` does by default, it is
/// not exactly the same. If you would like to change it, you can assign a different
/// animation (or group of animations) to the ``highlightAnimation`` property.
/// You can also turn off the animation by setting this property to `nil`.
open class MenuItemView: NSView {
	// MARK: - Properties
	public var autoHighlightSubviews = true
	
	public var highlightAnimation: CAAnimation? = {
		let animationDuration = 0.05
		
		let alphaAnimation = CABasicAnimation(keyPath: "alphaValue")
		alphaAnimation.beginTime = 0
		alphaAnimation.fromValue = NSNumber(value: 1)
		alphaAnimation.toValue = NSNumber(value: 0)
		alphaAnimation.duration = animationDuration
		
		let alphaAnimation1 = CABasicAnimation(keyPath: "opacity")
		alphaAnimation1.beginTime = animationDuration
		alphaAnimation1.fromValue = NSNumber(value: 0)
		alphaAnimation1.toValue = NSNumber(value: 1)
		alphaAnimation1.duration = animationDuration
		
		let group = CAAnimationGroup()
		group.repeatCount = 1
		group.animations = [alphaAnimation, alphaAnimation1]
		group.duration = animationDuration * 2
		group.isRemovedOnCompletion = true
		
		return group
	}()
	
	// MARK: - Constants
	public let highlightMargins: NSEdgeInsets = .init(
		top: 4,
		left: 6,
		bottom: 4,
		right: 6
	)
	
	public let contentMargins: NSEdgeInsets = .init(
		top: 8,
		left: 12,
		bottom: 8,
		right: 12
	)
	
	// MARK: - Views
	public lazy var highlightView: NSVisualEffectView = {
		let view = NSVisualEffectView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.state = .active
		view.material = .selection
		view.blendingMode = .behindWindow
		view.isEmphasized = true
		return view
	}()
	
	private lazy var innerContentGuide = NSLayoutGuide()
	
	// MARK: - Initializers
	
	public convenience init(content: NSView) {
		self.init()
		addSubview(content, layoutAutomatically: true)
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setup()
	}
	
	required public init?(coder: NSCoder) {
		super.init(coder: coder)
		autoHighlightSubviews = coder.decodeBool(forKey: CoderKey.autoHighlightViews.rawValue)
		
		setup()
	}
	
	public override func encode(with coder: NSCoder) {
		super.encode(with: coder)
		coder.encode(autoHighlightSubviews, forKey: CoderKey.autoHighlightViews.rawValue)
	}
	
	// MARK: - Layout
	
	public override var allowsVibrancy: Bool { false }
	
	public override var layoutMarginsGuide: NSLayoutGuide {
		innerContentGuide
	}
	
	public override var intrinsicContentSize: NSSize {
		subviews
			.map { $0.intrinsicContentSize }
			.max { $0.width < $1.width } ?? .zero
	}
	
	public override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		let isHighlighted = enclosingMenuItem?.isHighlighted ?? false
		let isEnabled = enclosingMenuItem?.isEnabled ?? true
		
		highlightView.isHidden = !isHighlighted
		
		subviews
			.forEach { highlightIfNeeded($0, isHighlighted: isHighlighted, isEnabled: isEnabled) }
	}
	
	public func addSubview(_ view: NSView, layoutAutomatically: Bool) {
		translatesAutoresizingMaskIntoConstraints = false
		view.translatesAutoresizingMaskIntoConstraints = false
		
		addSubview(view)
		NSLayoutConstraint.activate([
			view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
			view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
		])
	}
	
	// MARK: - Events Handling
	
	public override func mouseUp(with event: NSEvent) {
		super.mouseUp(with: event)
		
		guard
			let enclosingMenuItem,
			enclosingMenuItem.isEnabled,
			let menu = enclosingMenuItem.menu
		else { return }
		
		animateHighlightAndInvoke(
			actionOfItemAt: menu.index(
				of: enclosingMenuItem
			),
			in: menu
		)
	}
	
	// MARK: - Highlighting
	open func highlightIfNeeded(_ view: NSView, isHighlighted: Bool, isEnabled: Bool) {
		guard
			autoHighlightSubviews
		else {
			return
		}
		
		if
			let textField = view as? NSTextField
		{
			textField.textColor = colorConsidering(isHighlighted: isHighlighted, isEnabled: isEnabled)
		} else if
			let imageView = view as? NSImageView,
			imageView.image?.isTemplate == true,
			#available(macOS 10.14, *)
		{
			imageView.contentTintColor = colorConsidering(isHighlighted: isHighlighted, isEnabled: isEnabled)
		}
		
		view.subviews
			.forEach { highlightIfNeeded($0, isHighlighted: isHighlighted, isEnabled: isEnabled) }
	}
}

// MARK: - Setup
private extension MenuItemView {
	func setup() {
		setupHighlightView()
		setupLayoutGuide()
	}
	
	func setupHighlightView() {
		addSubview(highlightView)
		highlightView.isHidden = true
		highlightView.wantsLayer = true
		highlightView.layer?.cornerRadius = 4
		
		NSLayoutConstraint.activate([
			highlightView.topAnchor.constraint(equalTo: topAnchor, constant: highlightMargins.top),
			highlightView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -highlightMargins.bottom),
			highlightView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: highlightMargins.left),
			highlightView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -highlightMargins.right)
		])
	}
	
	func setupLayoutGuide() {
		addLayoutGuide(innerContentGuide)
		NSLayoutConstraint.activate([
			innerContentGuide.topAnchor.constraint(equalTo: topAnchor, constant: contentMargins.top),
			innerContentGuide.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentMargins.bottom),
			innerContentGuide.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentMargins.left),
			innerContentGuide.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentMargins.right)
		])
	}
}

// MARK: - Highlight
public extension MenuItemView {
	func colorConsidering(isHighlighted: Bool, isEnabled: Bool) -> NSColor {
		if isHighlighted {
			return .selectedMenuItemTextColor
		} else if !isEnabled {
			return .disabledControlTextColor
		} else {
			return .controlTextColor
		}
	}
}

// MARK: - Animation
private extension MenuItemView {
	func animateHighlightAndInvoke(actionOfItemAt itemIndex: Int, in menu: NSMenu) {
		let completion = {
			menu.performActionForItem(
				at: itemIndex
			)
			
			menu.cancelTracking()
		}
		
		guard
			let animation = highlightAnimation
		else {
			return completion()
		}
		
		CATransaction.begin()
		CATransaction.setCompletionBlock(completion)
		highlightView.layer?.add(animation, forKey: nil)
		
		CATransaction.commit()
	}
}

// MARK: - Coding
private extension MenuItemView {
	enum CoderKey: String {
		case	autoHighlightViews
	}
}
#endif
