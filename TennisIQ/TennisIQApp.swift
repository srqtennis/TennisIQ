import SwiftUI

@main
struct TennisIQApp: App {
    @StateObject private var store = GameStore()
    @StateObject private var purchases = PurchaseStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(purchases)
                .task { await purchases.load() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await purchases.refreshEntitlements() } }
                }
                .preferredColorScheme(.dark)
        }
    }
}
