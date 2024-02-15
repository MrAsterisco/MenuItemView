//
//  ContentView.swift
//  MenuItemSwiftUIExample
//
//  Created by Alessio Moiso on 15.02.24.
//

import SwiftUI
import MenuItemView

struct ContentView: View {
	var body: some View {
		VStack {
			MenuItem {
				Text("Test")
			}
			
			Menu {
				Button(action: { }) {
					
				}
			 
				Button(action: { }) {
					Text("Standard Menu Item")
				}
			} label: {
				Text("Click me")
			}
			.padding()
		}
	}
}

#Preview {
	ContentView()
}
