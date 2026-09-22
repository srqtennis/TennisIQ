import SwiftUI
import StoreKit

struct PaywallView: View {
    var dismissOnUnlock = true
    @EnvironmentObject var store: PurchaseStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Unlock the full game")
                        .font(.largeTitle.bold())
                    Text("Daily Rally is free forever. Play your daily round without buying anything.")
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Shot Clock: race the timer", systemImage: "timer")
                        Label("Practice: learn at your pace", systemImage: "figure.tennis")
                        Label("Browse the full question bank", systemImage: "books.vertical")
                        Label("Knowledge rating, placement and badges", systemImage: "medal")
                        Label("Result cards and friendly challenge links", systemImage: "square.and.arrow.up")
                    }
                    Text("One purchase. No subscription.")
                        .font(.headline)
                    Button {
                        Task { await store.purchase() }
                    } label: {
                        Text(store.product.map { "Unlock for \($0.displayPrice)" } ?? "Unlock unavailable")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.89, green: 0.76, blue: 0.42))
                    .foregroundStyle(.black)
                    .controlSize(.large)
                    .disabled(store.product == nil || store.isLoading || store.isUnlocked)
                    .accessibilityIdentifier("paywall.purchase")

                    if store.isLoading {
                        ProgressView("Connecting to the App Store…")
                            .accessibilityIdentifier("paywall.loading")
                    }
                    if let message = store.message {
                        Text(message)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("paywall.message")
                    }
                    if store.product == nil {
                        Button("Try Again") { Task { await store.load() } }
                            .disabled(store.isLoading)
                            .accessibilityIdentifier("paywall.retry")
                    }
                    Button("Restore Purchases") { Task { await store.restore() } }
                        .disabled(store.isLoading)
                        .accessibilityIdentifier("paywall.restore")
                    Text("Payment is handled by Apple. Restore a previous purchase using the same Apple Account.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .navigationTitle("Full Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                        .accessibilityIdentifier("paywall.close")
                }
            }
        }
        .accessibilityIdentifier("paywall")
        .task {
            if store.isUnlocked && dismissOnUnlock { dismiss() }
            else if store.product == nil { await store.load() }
        }
        .onChange(of: store.isUnlocked) { _, unlocked in
            if unlocked && dismissOnUnlock { dismiss() }
        }
    }
}
