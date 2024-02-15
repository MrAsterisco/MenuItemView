//
//  File.swift
//  
//
//  Created by Alessio Moiso on 15.02.24.
//

#if canImport(SwiftUI)
import SwiftUI

/// A view that wraps content to be displayed inside a menu item.
///
/// - warning: This view doesn't currently work because SwiftUI doesn't support
/// using views inside a `Menu` item.
@available(macOS 10.15, *)
public struct MenuItem<Content: View>: NSViewRepresentable {
	private let content: () -> Content
	
	public init(content: @escaping () -> Content) {
		self.content = content
	}
	
	public func makeNSView(context: Context) -> MenuItemView {
		MenuItemView(
			content: NSHostingView(
				rootView: content()
			)
		)
	}
	
	public func updateNSView(_ nsView: MenuItemView, context: Context) {
		nsView.subviews
			.forEach { $0.removeFromSuperview() }
		
		nsView.addSubview(
			NSHostingView(rootView: content()),
			layoutAutomatically: true
		)
	}
}
#endif
