// swiftlint:disable file_length
import Observation
import OSLog
import StoreKit
import SwiftUI

enum StitchwiseProEntitlement: Equatable {
    case checking
    case locked
    case unlocked
}

enum StitchwiseProStorefrontState: Equatable {
    case loading
    case available
    case unavailable(String)
}

enum StitchwiseProPurchaseState: Equatable {
    case pending
    case restoring
    case failure(String)
    case restored
    case nothingToRestore
}

#if TESTING
@MainActor private func defaultEntitlement() async -> StitchwiseProEntitlement { .locked }
@MainActor private func defaultSyncPurchases() async throws {}
@MainActor private func defaultProduct() async throws -> Product? { nil }
#else
@MainActor private func defaultEntitlement() async -> StitchwiseProEntitlement {
    await StitchwiseProStore.currentEntitlement()
}

@MainActor private func defaultSyncPurchases() async throws {
    try await AppStore.sync()
}

@MainActor private func defaultProduct() async throws -> Product? {
    try await Product.products(for: [StitchwiseProStore.productID]).first {
        $0.id == StitchwiseProStore.productID
    }
}
#endif

@MainActor
@Observable
final class StitchwiseProStore {
    static let productID = "com.yashasg.stitchwise.pro"

    private(set) var entitlement: StitchwiseProEntitlement = .checking
    private(set) var storefrontState: StitchwiseProStorefrontState = .loading
    private(set) var purchaseState: StitchwiseProPurchaseState?
    private(set) var product: Product?

    var isUnlocked: Bool {
        entitlement == .unlocked
    }

    var isChecking: Bool {
        entitlement == .checking
    }

    @ObservationIgnored
    private var transactionUpdatesTask: Task<Void, Never>?
    @ObservationIgnored
    private var isProductLoadInFlight = false
    @ObservationIgnored
    private var isRestoreInFlight = false
    @ObservationIgnored
    private let entitlementProvider: @MainActor () async -> StitchwiseProEntitlement
    @ObservationIgnored
    private let syncPurchases: @MainActor () async throws -> Void
    @ObservationIgnored
    private let productLoader: @MainActor () async throws -> Product?

    #if !TESTING
    private static let logger = Logger(
        subsystem: "com.yashasg.stitchwise", category: "StitchwisePro"
    )
    #endif

    init(
        entitlement: StitchwiseProEntitlement = .checking,
        storefrontState: StitchwiseProStorefrontState = .loading,
        startsTransactionListener: Bool = true,
        entitlementProvider: @escaping @MainActor () async -> StitchwiseProEntitlement =
            defaultEntitlement,
        syncPurchases: @escaping @MainActor () async throws -> Void =
            defaultSyncPurchases,
        productLoader: @escaping @MainActor () async throws -> Product? =
            defaultProduct
    ) {
        self.entitlement = entitlement
        self.storefrontState = storefrontState
        self.entitlementProvider = entitlementProvider
        self.syncPurchases = syncPurchases
        self.productLoader = productLoader

        #if !TESTING
        if startsTransactionListener {
            transactionUpdatesTask = Task(priority: .background) { [weak self] in
                for await result in StoreKit.Transaction.updates {
                    guard !Task.isCancelled else { return }
                    await self?.handleTransactionUpdate(result)
                }
            }
        }
        #endif
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func refresh() async {
        entitlement = .checking
        entitlement = await entitlementProvider()
    }

    func loadProduct(forceReload: Bool = false) async {
        guard !isProductLoadInFlight else { return }
        #if !TESTING
        if product != nil, !forceReload {
            storefrontState = .available
            return
        }
        #endif

        isProductLoadInFlight = true
        storefrontState = .loading
        defer { isProductLoadInFlight = false }

        do {
            product = try await productLoader()
            storefrontState = product == nil
                ? .unavailable(
                    "Stitchwise Pro is not available from the App Store right now. Please try again."
                )
                : .available
        } catch {
            product = nil
            storefrontState = .unavailable(
                "The App Store could not load Stitchwise Pro. Check your connection and try again."
            )
            #if !TESTING
            Self.logger.error(
                "Product load failed: \(error.localizedDescription, privacy: .public)"
            )
            #endif
        }
    }

    func restorePurchases() async {
        guard !isRestoreInFlight else { return }
        isRestoreInFlight = true
        purchaseState = .restoring
        defer { isRestoreInFlight = false }

        do {
            try await syncPurchases()
            await refresh()
            purchaseState = isUnlocked ? .restored : .nothingToRestore
        } catch {
            purchaseState = .failure(
                "Purchases could not be restored. Check your App Store connection and try again."
            )
            #if !TESTING
            Self.logger.error(
                "Restore failed: \(error.localizedDescription, privacy: .public)"
            )
            #endif
        }
    }

    func retryProductLoad() async {
        await loadProduct(forceReload: true)
    }

    func clearPurchaseState() {
        purchaseState = nil
    }

#if DEBUG || TESTING
    func setEntitlementForTesting(_ entitlement: StitchwiseProEntitlement) {
        self.entitlement = entitlement
    }

    func setPurchaseStateForTesting(_ purchaseState: StitchwiseProPurchaseState?) {
        self.purchaseState = purchaseState
    }
#endif

    func handlePurchaseCompletion(
        productID: Product.ID,
        result: Result<Product.PurchaseResult, any Error>
    ) async {
        guard productID == Self.productID else {
            #if !TESTING
            Self.logger.error(
                "Ignored purchase callback for unexpected product \(productID, privacy: .public)"
            )
            #endif
            return
        }

        switch result {
        case .failure(let error):
            purchaseState = .failure(
                "The purchase could not be completed. Check your connection and try again."
            )
            #if !TESTING
            Self.logger.error(
                "Purchase failed: \(error.localizedDescription, privacy: .public)"
            )
            #endif
        case .success(let purchaseResult):
            #if TESTING
            switch purchaseResult {
            case .userCancelled:
                purchaseState = nil
            default:
                purchaseState = .pending
            }
            #else
            switch purchaseResult {
            case .userCancelled:
                purchaseState = nil
            case .pending:
                purchaseState = .pending
            case .success(let verification):
                await handlePurchaseVerification(verification)
            @unknown default:
                purchaseState = .failure(
                    "The App Store returned an unknown purchase result. Please try again."
                )
            }
            #endif
        }
    }

    #if !TESTING
    func handlePurchaseVerification(
        _ verification: VerificationResult<StoreKit.Transaction>
    ) async {
        switch verification {
        case .verified(let transaction):
            await processVerifiedTransaction(transaction)
        case .unverified(_, let error):
            purchaseState = .failure(
                "The App Store could not verify this purchase. Try Restore Purchases."
            )
            Self.logger.error(
                "Purchase verification failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func handleTransactionUpdate(
        _ result: VerificationResult<StoreKit.Transaction>
    ) async {
        switch result {
        case .verified(let transaction):
            await processVerifiedTransaction(transaction)
        case .unverified(_, let error):
            Self.logger.error(
                "Unverified transaction update: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func processVerifiedTransaction(_ transaction: StoreKit.Transaction) async {
        await processVerifiedTransaction(
            productID: transaction.productID,
            isRevoked: transaction.revocationDate != nil,
            finish: transaction.finish
        )
    }
    #endif

    func processVerifiedTransaction(
        productID: Product.ID,
        isRevoked: Bool,
        finish: @escaping @Sendable () async -> Void
    ) async {
        guard productID == Self.productID else {
            #if !TESTING
            Self.logger.info(
                "Ignored transaction for unexpected product \(productID, privacy: .public)"
            )
            #endif
            return
        }

        if !isRevoked {
            entitlement = .unlocked
            purchaseState = nil
            await finish()
        } else {
            entitlement = .checking
            await finish()
            await refresh()
        }
    }

    #if !TESTING
    fileprivate static func currentEntitlement() async -> StitchwiseProEntitlement {
        var hasVerifiedEntitlement = false
        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == Self.productID,
                   transaction.revocationDate == nil {
                    hasVerifiedEntitlement = true
                }
            case .unverified(_, let error):
                Self.logger.error(
                    "Unverified current entitlement: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
        return hasVerifiedEntitlement ? .unlocked : .locked
    }
    #endif
}

enum StitchwiseProContext: Equatable {
    case general
    case project(type: ProjectType, projectLimitReached: Bool)
}

enum StitchwiseProPresentationOutcome: Equatable {
    case purchaseCancelled
}

private func ignoreProPresentationOutcome(_: StitchwiseProPresentationOutcome) {}

struct StitchwiseProView: View {
    @Environment(StitchwiseProStore.self) private var store

    private let context: StitchwiseProContext
    private let onPresentationOutcome: (StitchwiseProPresentationOutcome) -> Void
    private let storeOverride: StitchwiseProStore?

    init(
        context: StitchwiseProContext = .general,
        onPresentationOutcome: @escaping (StitchwiseProPresentationOutcome) -> Void =
            ignoreProPresentationOutcome,
        store: StitchwiseProStore? = nil
    ) {
        self.context = context
        self.onPresentationOutcome = onPresentationOutcome
        storeOverride = store
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.roomy) {
                VStack(alignment: .leading, spacing: Spacing.tight) {
                    Text("Stitchwise Pro")
                        .font(.satoshiTitle)
                        .foregroundStyle(AppTheme.ink)
                    Text("One-time purchase. No subscription.")
                        .font(.satoshiHeadline)
                        .foregroundStyle(AppTheme.terracotta)
                    Text(context.explanation)
                        .font(.satoshiBody)
                        .foregroundStyle(AppTheme.muted)
                        .padding(.top, Spacing.compact)
                }

                StitchwiseProComparison()

                if let purchaseState = activeStore.purchaseState {
                    StitchwiseProStatusView(state: purchaseState)
                }

                purchaseControls
            }
            .frame(maxWidth: Sizing.maximumContentWidth, alignment: .leading)
            .padding(Spacing.margin)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(AppTheme.background)
        .navigationTitle("Stitchwise Pro")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.terracotta)
    }

    @ViewBuilder
    private var purchaseControls: some View {
        if activeStore.isChecking {
            HStack(spacing: Spacing.control) {
                ProgressView()
                Text("Checking your Stitchwise Pro purchase…")
                    .foregroundStyle(AppTheme.muted)
            }
            .font(.satoshiBody)
            .accessibilityElement(children: .combine)
        } else if activeStore.isUnlocked {
            Label("Stitchwise Pro is unlocked.", systemImage: "checkmark.circle.fill")
                .font(.satoshiHeadline)
                .foregroundStyle(.green)
                .accessibilityLabel("Stitchwise Pro is unlocked")
        } else {
            VStack(alignment: .leading, spacing: Spacing.margin) {
                storefrontControl

                Button(action: restorePurchases) {
                    if activeStore.purchaseState == .restoring {
                        HStack(spacing: Spacing.inner) {
                            ProgressView()
                            Text("Restoring…")
                        }
                    } else {
                        Text("Restore Purchases")
                    }
                }
                .font(.satoshiHeadline)
                .buttonStyle(.bordered)
                .disabled(activeStore.purchaseState == .restoring)
                .accessibilityHint("Checks the App Store for a previous Stitchwise Pro purchase")
            }
        }
    }

    @ViewBuilder
    private var storefrontControl: some View {
        switch activeStore.storefrontState {
        case .loading:
            HStack(spacing: Spacing.control) {
                ProgressView()
                Text("Loading purchase options from the App Store…")
                    .foregroundStyle(AppTheme.muted)
            }
            .font(.satoshiBody)
            .accessibilityElement(children: .combine)
        case .available:
            #if TESTING
            unavailableStorefront(
                "Stitchwise Pro is not available from the App Store right now."
            )
            #else
            if let product = activeStore.product {
                ProductView(product, prefersPromotionalIcon: false)
                    .productViewStyle(.regular)
                    .onInAppPurchaseStart(perform: purchaseStarted)
                    .onInAppPurchaseCompletion(perform: purchaseCompleted)
            } else {
                unavailableStorefront(
                    "Stitchwise Pro is not available from the App Store right now."
                )
            }
            #endif
        case .unavailable(let message):
            unavailableStorefront(message)
        }
    }

    private func unavailableStorefront(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.control) {
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.satoshiBody)
                .foregroundStyle(AppTheme.warningText)
            Button("Try Again", action: retryProductLoad)
            .font(.satoshiHeadline)
            .buttonStyle(.bordered)
        }
    }

    func handlePresentationOutcome(
        _ result: Result<Product.PurchaseResult, any Error>
    ) {
        guard case .project = context,
              case .success(let purchaseResult) = result else {
            return
        }

        switch purchaseResult {
        case .userCancelled:
            onPresentationOutcome(.purchaseCancelled)
        case .pending, .success:
            break
        @unknown default: break
        }
    }

    #if !TESTING
    private func purchaseStarted(_: Product) {
        activeStore.clearPurchaseState()
    }

    private func purchaseCompleted(
        product: Product,
        result: Result<Product.PurchaseResult, any Error>
    ) async {
        await activeStore.handlePurchaseCompletion(productID: product.id, result: result)
        handlePresentationOutcome(result)
    }
    #endif

    func restorePurchases() {
        Task {
            await activeStore.restorePurchases()
        }
    }

    func retryProductLoad() {
        Task {
            await activeStore.retryProductLoad()
        }
    }

    private var activeStore: StitchwiseProStore {
        storeOverride ?? store
    }
}

struct StitchwiseProSheet: View {
    #if !TESTING
    @Environment(\.dismiss) private var dismiss
    #endif

    private let context: StitchwiseProContext
    private let onPresentationOutcome: (StitchwiseProPresentationOutcome) -> Void
    private let dismissAction: (() -> Void)?

    init(
        context: StitchwiseProContext = .general,
        onPresentationOutcome: @escaping (StitchwiseProPresentationOutcome) -> Void =
            ignoreProPresentationOutcome,
        dismissAction: (() -> Void)? = nil
    ) {
        self.context = context
        self.onPresentationOutcome = onPresentationOutcome
        self.dismissAction = dismissAction
    }

    var body: some View {
        NavigationStack {
            StitchwiseProView(
                context: context,
                onPresentationOutcome: onPresentationOutcome
            )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close", action: close)
                    }
                }
        }
    }

    func close() {
        #if TESTING
        dismissAction?()
        #else
        if let dismissAction {
            dismissAction()
        } else {
            dismiss()
        }
        #endif
    }
}

struct ProBadge: View {
    var body: some View {
        Text("Pro")
            .font(.satoshiCaption2.weight(.bold))
            .foregroundStyle(AppTheme.terracotta)
            .padding(.horizontal, Spacing.inner)
            .padding(.vertical, Spacing.tight)
            .background(AppTheme.card)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(AppTheme.terracotta, lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

private extension StitchwiseProContext {
    var explanation: String {
        switch self {
        case .general:
            return "Unlock every project type and save as many projects as you like."
        case .project(let type, let projectLimitReached):
            if type != .headwear, projectLimitReached {
                return "\(type.label) projects and saving beyond three projects require Stitchwise Pro."
            }
            if type != .headwear {
                return "\(type.label) projects are available with Stitchwise Pro."
            }
            if projectLimitReached {
                return "You have reached the three-project Free limit. Stitchwise Pro removes it."
            }
            return "Unlock every project type and unlimited saved projects."
        }
    }
}

private struct StitchwiseProComparison: View {
    private let items = [
        StitchwiseProComparisonItem(
            feature: "Complete reconciliation",
            free: .included,
            pro: .included
        ),
        StitchwiseProComparisonItem(
            feature: "Project types",
            free: .text("Headwear only"),
            pro: .text("All project types")
        ),
        StitchwiseProComparisonItem(
            feature: "Saved projects",
            free: .text("Up to 3"),
            pro: .text("Unlimited")
        ),
        StitchwiseProComparisonItem(
            feature: "Share results",
            free: .included,
            pro: .included
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.control) {
            Text("Compare plans")
                .font(.satoshiTitle3)
                .foregroundStyle(AppTheme.ink)

            ViewThatFits(in: .horizontal) {
                comparisonGrid
                    .fixedSize(horizontal: true, vertical: false)
                comparisonList
            }
        }
    }

    private var comparisonGrid: some View {
        Grid(
            alignment: .leading,
            horizontalSpacing: Spacing.margin,
            verticalSpacing: Spacing.control
        ) {
            GridRow {
                Text("Feature")
                    .accessibilityHidden(true)
                Text("Free")
                    .font(.satoshiHeadline)
                Text("Pro")
                    .font(.satoshiHeadline)
            }

            Divider()
                .gridCellColumns(3)

            ForEach(items) { item in
                GridRow {
                    Text(item.feature)
                        .font(.satoshiBody)
                    StitchwiseProComparisonValueView(value: item.free)
                    StitchwiseProComparisonValueView(value: item.pro)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.accessibilityLabel)
            }
        }
        .foregroundStyle(AppTheme.ink)
    }

    private var comparisonList: some View {
        VStack(alignment: .leading, spacing: Spacing.margin) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: Spacing.inner) {
                    Text(item.feature)
                        .font(.satoshiHeadline)
                    LabeledContent {
                        StitchwiseProComparisonValueView(value: item.free)
                    } label: {
                        Text("Free")
                    }
                    LabeledContent {
                        StitchwiseProComparisonValueView(value: item.pro)
                    } label: {
                        Text("Pro")
                    }
                }
                .font(.satoshiBody)
                .foregroundStyle(AppTheme.ink)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.accessibilityLabel)

                if item.id != items.last?.id {
                    Divider()
                }
            }
        }
    }
}

private struct StitchwiseProComparisonItem: Identifiable {
    let feature: String
    let free: StitchwiseProComparisonValue
    let pro: StitchwiseProComparisonValue

    var id: String {
        feature
    }

    var accessibilityLabel: String {
        "\(feature). Free: \(free.accessibilityText). Pro: \(pro.accessibilityText)."
    }
}

private enum StitchwiseProComparisonValue {
    case included
    case text(String)

    var accessibilityText: String {
        switch self {
        case .included:
            "Included"
        case .text(let value):
            value
        }
    }
}

private struct StitchwiseProComparisonValueView: View {
    let value: StitchwiseProComparisonValue

    var body: some View {
        switch value {
        case .included:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Included")
        case .text(let value):
            Text(value)
                .font(.satoshiSubheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct StitchwiseProStatusView: View {
    let state: StitchwiseProPurchaseState

    var body: some View {
        Label(message, systemImage: symbolName)
            .font(.satoshiBody)
            .foregroundStyle(foregroundStyle)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
    }

    private var message: String {
        switch state {
        case .pending:
            "Purchase approval is pending. Stitchwise Pro will unlock after the App Store approves it."
        case .restoring:
            "Checking the App Store for previous purchases…"
        case .failure(let message):
            message
        case .restored:
            "Your Stitchwise Pro purchase was restored."
        case .nothingToRestore:
            "No previous Stitchwise Pro purchase was found for this App Store account."
        }
    }

    private var symbolName: String {
        switch state {
        case .pending, .restoring:
            "clock"
        case .failure:
            "exclamationmark.triangle"
        case .restored:
            "checkmark.circle.fill"
        case .nothingToRestore:
            "info.circle"
        }
    }

    private var foregroundStyle: Color {
        switch state {
        case .failure:
            AppTheme.warningText
        case .restored:
            .green
        case .pending, .restoring, .nothingToRestore:
            AppTheme.muted
        }
    }
}
