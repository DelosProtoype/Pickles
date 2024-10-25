//
//  PicklesApp.swift
//  Pickles
//
//  Created by Kevin ONeil on 10/24/24.
//

import SwiftUI

@main
struct PicklesApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
