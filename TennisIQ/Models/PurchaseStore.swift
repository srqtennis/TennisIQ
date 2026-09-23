import Foundation
import Combine
import StoreKit

@MainActor
final class PurchaseStore: ObservableObject {
    static let productID = "com.srqtennis.TennisIQ.fullunlock"

    @Published private(set) var isUnlocked = false
    @Published private(set) var isLoading = false
    @Published private(set) var product: Product?
    @Published var message: String?

    private var updatesTask: Task<Void, Never>?
    private var entitlementRevision = 0

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                await self?.handle(result)
            }
        }
        Task { [weak self] in await self?.load() }
    }

    deinit { updatesTask?.cancel() }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        message = nil
        defer { isLoading = false }
        await refreshEntitlements()
        do {
            product = try await Product.products(for: [Self.productID])
                .first { $0.id == Self.productID && $0.type == .nonConsumable }
            if product == nil {
                message = "The unlock is currently unavailable. Please try again. Daily Rally is still free."
            }
        } catch {
            product = nil
            message = "Couldn’t load the unlock: \(error.localizedDescription)"
        }
    }

    func purchase() async {
        guard !isLoading, !isUnlocked else { return }
        guard let product else {
            message = "The unlock hasn’t loaded. Please try again."
            return
        }
        isLoading = true
        message = nil
        defer { isLoading = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                await handle(result)
            case .pending:
                message = "Your purchase is pending approval. The full game will unlock when Apple confirms it."
            case .userCancelled:
                message = "Purchase cancelled. Daily Rally is still free."
            @unknown default:
                message = "The purchase hasn’t completed. Please try again."
            }
        } catch {
            message = "Couldn’t complete the purchase: \(error.localizedDescription)"
        }
    }

    func restore() async {
        guard !isLoading else { return }
        isLoading = true
        message = nil
        defer { isLoading = false }
        do {
            // Sync can prompt for authentication, so only call after a restore tap.
            try await AppStore.sync()
            await refreshEntitlements()
            message = isUnlocked ? "Your full game is restored." : "No full-game purchase was found for this Apple Account."
        } catch {
            message = "Couldn’t restore purchases: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        entitlementRevision += 1
        let revision = entitlementRevision
        var ownsUnlock = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.productID,
                  transaction.productType == .nonConsumable,
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded else { continue }
            ownsUnlock = true
        }
        guard revision == entitlementRevision else { return }
        isUnlocked = ownsUnlock
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            guard transaction.productID == Self.productID else { return }
            await refreshEntitlements()
            // Deliver verified access (or remove revoked access) before finishing.
            await transaction.finish()
            if transaction.revocationDate != nil {
                message = "The full-game purchase is no longer active. Daily Rally is still free."
            } else if isUnlocked {
                message = "The full game is unlocked."
            }
        case .unverified:
            await refreshEntitlements()
            message = "Apple couldn’t verify this purchase. Please try Restore Purchases or contact support."
        }
    }
}
