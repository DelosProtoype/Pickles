//
//  PicklesApp.swift
//  Pickles
//
//  Created by Kevin ONeil on 10/24/24.
//

import SwiftUI

@main
struct PicklesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("Pickles Help") {
                    NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(
                        NSHostingController(rootView: HelpView())
                    )
                }
            }
        }
    }
}
