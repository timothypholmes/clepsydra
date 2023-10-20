//
//  clepsydraApp.swift
//  clepsydra
//
//  Created by Tim Holmes on 10/18/23.
//

import SwiftUI


@main
struct TimerApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(width: 300, height: 200)
        .background(VisualEffectView()) // Set the background color to clear
        //.edgesIgnoringSafeArea(.all) // Extend content to the edges of the window
    }
    .windowStyle(.hiddenTitleBar) // Hide the window title bar
    .windowResizability(.contentSize)
  }
}
