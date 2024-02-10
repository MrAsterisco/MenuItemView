//
//  ViewController.swift
//  MenuItemViewExample
//
//  Created by Alessio Moiso on 06.02.24.
//

import Cocoa
import MenuItemView

class ViewController: NSViewController {
	private static let testMenuItemIdentifier = "co.mrasteris.menu.Test"
	
	@IBOutlet weak var button: NSPopUpButton!
	@IBOutlet weak var autoHighlight: NSButton!
	
	private lazy var popupButtonMenuItemView: MenuItemView = {
		MenuItemView(
			content: customView(
				title: "Title",
				subtitle: "An item inside a popup button.",
				symbolName: "info.circle.fill"
			)
		)
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let item = NSMenuItem(title: "Title", action: nil, keyEquivalent: "")
		item.view = popupButtonMenuItemView
		popupButtonMenuItemView.autoHighlightSubviews = autoHighlight.state == .on
		
		button.menu?.insertItem(item, at: 0)
		
		guard
			let testMenu = NSApp.mainMenu?.items.first(where: {
				$0.identifier?.rawValue == Self.testMenuItemIdentifier
			})
		else {
			return
		}
		
		let enabledItem = NSMenuItem(title: "Enabled Item", action: #selector(ViewController.didSelectItem(sender:)), keyEquivalent: "")
		enabledItem.target = self
		enabledItem.view = MenuItemView(
			content: customView(
				title: "Enabled Item",
				subtitle: "An item inside the menu bar.",
				symbolName: "menucard"
			)
		)
		
		testMenu.submenu?.addItem(enabledItem)
		
		let disabledItem = NSMenuItem(title: "Disabled Item", action: nil, keyEquivalent: "")
		disabledItem.view = MenuItemView(
			content: customView(
				title: "Disabled Item",
				subtitle: "Another item inside the menu bar.",
				symbolName: "lightswitch.off"
			)
		)
		
		testMenu.submenu?.addItem(disabledItem)
		
		let noHighlightItem = NSMenuItem(title: "Subviews Not Highlighted", action: #selector(ViewController.didSelectItem(sender:)), keyEquivalent: "")
		noHighlightItem.target = self
		let noHighlightMenuView = MenuItemView(
			content: customView(
				title: "No Automatic Highlight",
				subtitle: "This item will not be highlighted automatically and it will not blink when clicked.",
				symbolName: "lightbulb.slash"
			)
		)
		noHighlightMenuView.autoHighlightSubviews = false
		noHighlightMenuView.highlightAnimation = nil
		noHighlightItem.view = noHighlightMenuView
		
		testMenu.submenu?.addItem(noHighlightItem)
	}
	
	@objc func didSelectItem(sender: NSMenuItem) {
		let alert = NSAlert()
		alert.messageText = "You clicked!"
		alert.informativeText = "Your selection: \(sender.title)"
		alert.runModal()
	}
	
	@IBAction func didChangeAutoHighlight(sender: NSButton) {
		popupButtonMenuItemView.autoHighlightSubviews = sender.state == .on
	}
}

private extension ViewController {
	func customView(title: String, subtitle: String, symbolName: String) -> NSView {
		let image = NSImageView(
			image: NSImage(
				systemSymbolName: symbolName,
				accessibilityDescription: nil
			)!
		)
		let title = NSTextField(
			labelWithString: title
		)
		title.font = .preferredFont(forTextStyle: .headline)
		
		let subtitle = NSTextField(
			labelWithString: subtitle
		)
		subtitle.font = .preferredFont(forTextStyle: .subheadline)
		
		let stackView = NSStackView(views: [title, subtitle])
		stackView.spacing = 4
		stackView.alignment = .leading
		stackView.orientation = .vertical
		
		return NSStackView(views: [image, stackView])
	}
}
