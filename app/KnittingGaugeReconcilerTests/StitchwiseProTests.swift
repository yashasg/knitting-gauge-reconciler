import SwiftData
import StoreKit
import SwiftUI
import Testing
import UIKit
@testable import KnittingGaugeReconciler

@Suite("Stitchwise Pro")
struct StitchwiseProTests {
    @MainActor
    @Test(arguments: [
        EntitlementCase(.checking, isChecking: true, isUnlocked: false),
        EntitlementCase(.locked, isChecking: false, isUnlocked: false),
        EntitlementCase(.unlocked, isChecking: false, isUnlocked: true),
    ])
    func entitlementStateIsDeterministic(_ testCase: EntitlementCase) {
        let store = StitchwiseProStore(
            entitlement: testCase.entitlement,
            storefrontState: .unavailable("Test storefront"),
            startsTransactionListener: false
        )

        #expect(store.entitlement == testCase.entitlement)
        #expect(store.isChecking == testCase.isChecking)
        #expect(store.isUnlocked == testCase.isUnlocked)
        #expect(store.storefrontState == .unavailable("Test storefront"))

        store.setEntitlementForTesting(.unlocked)
        #expect(store.entitlement == .unlocked)
        #expect(store.isUnlocked)
        #expect(!store.isChecking)
    }

    @MainActor
    @Test func storeKitConfigurationExercisesDeterministicStoreOutcomes() async throws {
        let store = StitchwiseProStore(
            entitlement: .locked,
            startsTransactionListener: false
        )

        await store.refresh()
        #expect(!store.isChecking)

        await store.loadProduct()
        #expect(store.product == nil)
        #expect(store.storefrontState != .loading)

        await store.retryProductLoad()
        #expect(store.storefrontState != .loading)

        await store.restorePurchases()
        #expect(store.purchaseState == .nothingToRestore)

        store.clearPurchaseState()
        #expect(store.purchaseState == nil)
    }

    @MainActor
    @Test func injectedStoreOperationsCoverRefreshRestoreAndPurchaseStates() async {
        let providedEntitlement = EntitlementBox(.unlocked)
        let store = StitchwiseProStore(
            entitlement: .locked,
            startsTransactionListener: false,
            entitlementProvider: { providedEntitlement.value },
            syncPurchases: {}
        )

        await store.refresh()
        #expect(store.isUnlocked)

        providedEntitlement.value = .locked
        await store.restorePurchases()
        #expect(store.purchaseState == .nothingToRestore)

        providedEntitlement.value = .unlocked
        await store.restorePurchases()
        #expect(store.purchaseState == .restored)

        let failingStore = StitchwiseProStore(
            entitlement: .locked,
            startsTransactionListener: false,
            entitlementProvider: { .locked },
            syncPurchases: { throw TestError.purchaseFailed }
        )
        await failingStore.restorePurchases()
        #expect(failingStore.purchaseState == .failure(
            "Purchases could not be restored. Check your App Store connection and try again."
        ))

        let productFailureStore = StitchwiseProStore(
            entitlement: .locked,
            startsTransactionListener: false,
            productLoader: { throw TestError.purchaseFailed }
        )
        await productFailureStore.loadProduct()
        #expect(productFailureStore.storefrontState == .unavailable(
            "The App Store could not load Stitchwise Pro. Check your connection and try again."
        ))

        await failingStore.handlePurchaseCompletion(
            productID: "unexpected.product",
            result: .failure(TestError.purchaseFailed)
        )
        #expect(failingStore.purchaseState != .pending)

        await failingStore.handlePurchaseCompletion(
            productID: StitchwiseProStore.productID,
            result: .failure(TestError.purchaseFailed)
        )
        #expect(failingStore.purchaseState == .failure(
            "The purchase could not be completed. Check your connection and try again."
        ))

        await failingStore.handlePurchaseCompletion(
            productID: StitchwiseProStore.productID,
            result: .success(.userCancelled)
        )
        #expect(failingStore.purchaseState == nil)

        await failingStore.handlePurchaseCompletion(
            productID: StitchwiseProStore.productID,
            result: .success(.pending)
        )
        #expect(failingStore.purchaseState == .pending)

        let finishCount = Counter()
        await failingStore.processVerifiedTransaction(
            productID: "unexpected.product",
            isRevoked: false,
            finish: { finishCount.increment() }
        )
        #expect(finishCount.value == 0)

        await failingStore.processVerifiedTransaction(
            productID: StitchwiseProStore.productID,
            isRevoked: false,
            finish: { finishCount.increment() }
        )
        #expect(failingStore.isUnlocked)
        #expect(finishCount.value == 1)

        await failingStore.processVerifiedTransaction(
            productID: StitchwiseProStore.productID,
            isRevoked: true,
            finish: { finishCount.increment() }
        )
        #expect(failingStore.entitlement == .locked)
        #expect(finishCount.value == 2)
    }

    @MainActor
    @Test func contextualPurchaseOutcomeOnlyReportsProjectCancellation() {
        var outcomes: [StitchwiseProPresentationOutcome] = []
        let general = StitchwiseProView(
            context: .general,
            onPresentationOutcome: { outcomes.append($0) }
        )
        general.handlePresentationOutcome(.success(.userCancelled))
        general.handlePresentationOutcome(.failure(TestError.purchaseFailed))
        #expect(outcomes.isEmpty)

        let project = StitchwiseProView(
            context: .project(type: .tops, projectLimitReached: false),
            onPresentationOutcome: { outcomes.append($0) }
        )
        project.handlePresentationOutcome(.failure(TestError.purchaseFailed))
        project.handlePresentationOutcome(.success(.pending))
        #expect(outcomes.isEmpty)
        project.handlePresentationOutcome(.success(.userCancelled))
        #expect(outcomes == [.purchaseCancelled])

        StitchwiseProView(
            context: .project(type: .tops, projectLimitReached: false)
        )
        .handlePresentationOutcome(.success(.userCancelled))
    }

    @MainActor
    @Test func appSceneAndContentConstructAndRefresh() async {
        let app = KnittingGaugeReconcilerApp(scenePhaseOverride: .inactive)
        _ = app.body
        _ = app.sceneContent()
        app.refreshStoreWhenActive(.inactive, .inactive)
        app.refreshStoreWhenActive(.inactive, .active)
        await app.refreshStore()

        let store = StitchwiseProStore(
            entitlement: .locked,
            storefrontState: .unavailable("Test"),
            startsTransactionListener: false
        )
        expectFinite(
            KnittingGaugeReconcilerApp.content(store: store)
                .frame(width: 320, height: 844),
            width: 320
        )
    }

    @MainActor
    @Test func proViewActionsInvokeStoreOperationsAndSheetDismissal() async {
        let store = StitchwiseProStore(
            entitlement: .locked,
            storefrontState: .unavailable("Test"),
            startsTransactionListener: false,
            entitlementProvider: { .unlocked },
            syncPurchases: {}
        )
        let view = StitchwiseProView(store: store)

        view.restorePurchases()
        while store.purchaseState == .restoring || store.purchaseState == nil {
            await Task.yield()
        }
        #expect(store.purchaseState == .restored)

        view.retryProductLoad()
        while store.storefrontState == .loading {
            await Task.yield()
        }
        #expect(store.storefrontState != .loading)

    }

    @MainActor
    @Test func createFlowViewContractsCoverEntitlementAndLifecycleBranches() throws {
        let projectStore = try projectStore()
        let draft = validDraft(type: .tops)

        let lockedProStore = StitchwiseProStore(
            entitlement: .locked,
            startsTransactionListener: false
        )
        let lockedState = CreateProjectFlowState(
            store: projectStore,
            onCreated: { _ in },
            draft: draft,
            step: .review
        )
        var flow = CreateProjectFlow(state: lockedState, proStore: lockedProStore)
        #expect(flow.isConfirmedLocked)
        #expect(flow.potentiallyRequiresPro)
        #expect(flow.requiresPro)
        #expect(flow.showsProBadge)
        #expect(!flow.showsCheckingAccess)
        #expect(flow.canAdvance)
        #expect(flow.primaryActionAccessibilityLabel.contains("requires Stitchwise Pro"))
        #expect(flow.primaryActionAccessibilityHint.contains("without saving"))
        _ = flow.primaryActionTitle
        _ = flow.primaryActionStatus
        _ = flow.primaryActionIcon

        flow.advance()
        #expect(lockedState.awaitingProCommit)
        flow.handleProUnlockChange(false, false)
        flow.handleProPresentationChange(true, true)
        #expect(lockedState.awaitingProCommit)
        flow.handleProPresentationChange(true, false)
        #expect(!lockedState.awaitingProCommit)

        lockedState.awaitingProCommit = true
        lockedState.isProPurchasePresented = true
        flow.handleProPresentationOutcome(.purchaseCancelled)
        #expect(!lockedState.awaitingProCommit)
        #expect(!lockedState.isProPurchasePresented)

        let checkingProStore = StitchwiseProStore(
            entitlement: .checking,
            startsTransactionListener: false
        )
        let checkingState = CreateProjectFlowState(
            store: projectStore,
            onCreated: { _ in },
            draft: draft,
            step: .review
        )
        flow = CreateProjectFlow(state: checkingState, proStore: checkingProStore)
        #expect(!flow.isConfirmedLocked)
        #expect(flow.potentiallyRequiresPro)
        #expect(flow.requiresPro)
        #expect(!flow.showsProBadge)
        #expect(flow.showsCheckingAccess)
        #expect(!flow.canAdvance)
        #expect(flow.primaryActionAccessibilityLabel.contains("checking access"))
        #expect(flow.primaryActionAccessibilityHint.contains("verified"))
        _ = flow.primaryActionStatus
        flow.advance()
        #expect(projectStore.projects.isEmpty)

        let unlockedProStore = StitchwiseProStore(
            entitlement: .unlocked,
            startsTransactionListener: false
        )
        var createdIDs: [UUID] = []
        let unlockedState = CreateProjectFlowState(
            store: projectStore,
            onCreated: { createdIDs.append($0) },
            draft: draft,
            step: .review,
            isProPurchasePresented: true,
            awaitingProCommit: true
        )
        flow = CreateProjectFlow(state: unlockedState, proStore: unlockedProStore)
        #expect(!flow.requiresPro)
        #expect(!flow.showsProBadge)
        #expect(!flow.showsCheckingAccess)
        #expect(flow.primaryActionAccessibilityLabel == "View Results")
        #expect(flow.primaryActionAccessibilityHint.contains("opens its results"))
        flow.handleProUnlockChange(false, true)
        #expect(createdIDs.count == 1)
        flow.resumeAwaitingProCommitIfPossible()
        #expect(createdIDs.count == 1)

        let backState = CreateProjectFlowState(
            store: projectStore,
            onCreated: { _ in },
            draft: draft,
            step: .notes
        )
        flow = CreateProjectFlow(state: backState, proStore: unlockedProStore)
        #expect(flow.primaryActionAccessibilityHint.contains("Continues"))
        flow.moveBack()
        #expect(backState.step == .measurements)
    }

    @Test(arguments: [
        AccessCase(.headwear, saved: 0, original: nil, unlocked: false, requiresPro: false),
        AccessCase(.headwear, saved: 1, original: nil, unlocked: false, requiresPro: false),
        AccessCase(.headwear, saved: 2, original: nil, unlocked: false, requiresPro: false),
        AccessCase(.headwear, saved: 3, original: nil, unlocked: false, requiresPro: true),
        AccessCase(.tops, saved: 0, original: nil, unlocked: false, requiresPro: true),
        AccessCase(.bottoms, saved: 0, original: nil, unlocked: false, requiresPro: true),
        AccessCase(.footwear, saved: 0, original: nil, unlocked: false, requiresPro: true),
        AccessCase(.other, saved: 0, original: nil, unlocked: false, requiresPro: true),
        AccessCase(.headwear, saved: 3, original: nil, unlocked: true, requiresPro: false),
        AccessCase(.tops, saved: 12, original: nil, unlocked: true, requiresPro: false),
        AccessCase(.bottoms, saved: 12, original: nil, unlocked: true, requiresPro: false),
        AccessCase(.footwear, saved: 12, original: nil, unlocked: true, requiresPro: false),
        AccessCase(.other, saved: 12, original: nil, unlocked: true, requiresPro: false),
        AccessCase(.headwear, saved: 3, original: .headwear, unlocked: false, requiresPro: false),
        AccessCase(.tops, saved: 12, original: .tops, unlocked: false, requiresPro: false),
        AccessCase(.bottoms, saved: 12, original: .bottoms, unlocked: false, requiresPro: false),
        AccessCase(.footwear, saved: 12, original: .footwear, unlocked: false, requiresPro: false),
        AccessCase(.other, saved: 12, original: .other, unlocked: false, requiresPro: false),
        AccessCase(.tops, saved: 1, original: .headwear, unlocked: false, requiresPro: true),
    ])
    func accessMatrix(_ testCase: AccessCase) {
        #expect(ProjectAccess.freeProjectLimit == 3)
        #expect(
            ProjectAccess.requiresPro(
                type: testCase.type,
                savedProjectCount: testCase.saved,
                originalType: testCase.original,
                isUnlocked: testCase.unlocked
            ) == testCase.requiresPro
        )
    }

    @MainActor
    @Test func proTypeTraversesEveryWizardStepBeforeReviewGate() throws {
        let store = try projectStore()
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { _ in Issue.record("Project saved before Review") },
            draft: validDraft(type: .tops)
        )

        for expectedStep in CreateProjectFlow.Step.allCases.dropFirst() {
            state.advance { .locked }
            #expect(state.step == expectedStep)
            #expect(!state.isProPurchasePresented)
            #expect(!state.awaitingProCommit)
            #expect(store.projects.isEmpty)
        }

        state.advance { .locked }
        #expect(state.step == .review)
        #expect(state.isProPurchasePresented)
        #expect(state.awaitingProCommit)
        #expect(store.projects.isEmpty)
    }

    @MainActor
    @Test(arguments: [
        GateCase(.tops, saved: 0),
        GateCase(.headwear, saved: ProjectAccess.freeProjectLimit),
    ])
    func lockedReviewAttemptsGateWithoutSaving(_ testCase: GateCase) throws {
        let store = try projectStore(savedProjectCount: testCase.saved)
        let originalCount = store.projects.count
        let draft = validDraft(type: testCase.type)
        var creationCount = 0
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { _ in creationCount += 1 },
            draft: draft,
            step: .review
        )

        state.advance { .locked }

        #expect(store.projects.count == originalCount)
        #expect(creationCount == 0)
        #expect(state.draft == draft)
        #expect(state.isProPurchasePresented)
        #expect(state.awaitingProCommit)
        #expect(!state.hasCommitted)
    }

    @MainActor
    @Test(arguments: [
        GateCase(.tops, saved: 0),
        GateCase(.headwear, saved: ProjectAccess.freeProjectLimit),
    ])
    func checkingEntitlementNeverSavesGatedProjects(_ testCase: GateCase) throws {
        let store = try projectStore(savedProjectCount: testCase.saved)
        let originalCount = store.projects.count
        var creationCount = 0
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { _ in creationCount += 1 },
            draft: validDraft(type: testCase.type),
            step: .review
        )

        state.advance { .checking }

        #expect(store.projects.count == originalCount)
        #expect(creationCount == 0)
        #expect(!state.isProPurchasePresented)
        #expect(!state.awaitingProCommit)
        #expect(!state.hasCommitted)
    }

    @MainActor
    @Test func cancelledPurchaseReturnsToReviewWithoutSaving() throws {
        let store = try projectStore()
        let draft = validDraft(type: .tops)
        var creationCount = 0
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { _ in creationCount += 1 },
            draft: draft,
            step: .review
        )

        state.advance { .locked }
        state.handleProPresentationOutcome(.purchaseCancelled)

        #expect(store.projects.isEmpty)
        #expect(creationCount == 0)
        #expect(state.draft == draft)
        #expect(state.step == .review)
        #expect(!state.awaitingProCommit)
        #expect(!state.isProPurchasePresented)
        #expect(!state.hasCommitted)
    }

    @MainActor
    @Test func pendingPurchaseWithoutOutcomeKeepsDestinationActiveAndUnsaved() throws {
        let store = try projectStore()
        let draft = validDraft(type: .tops)
        var creationCount = 0
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { _ in creationCount += 1 },
            draft: draft,
            step: .review
        )

        state.advance { .locked }

        #expect(store.projects.isEmpty)
        #expect(creationCount == 0)
        #expect(state.draft == draft)
        #expect(state.step == .review)
        #expect(state.awaitingProCommit)
        #expect(state.isProPurchasePresented)
        #expect(!state.hasCommitted)
    }

    @MainActor
    @Test func closeAndBackNeverSaveAndBackClearsIntent() throws {
        let store = try projectStore()
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { _ in Issue.record("A pending gate must not create a project") },
            draft: validDraft(type: .tops),
            step: .review
        )

        state.advance { .locked }
        let pendingCount = store.projects.count
        state.cancel()
        #expect(store.projects.count == pendingCount)
        #expect(state.showDiscardConfirmation)
        #expect(state.awaitingProCommit)

        state.moveBack()
        #expect(store.projects.count == pendingCount)
        #expect(state.step == .notes)
        #expect(!state.awaitingProCommit)
        #expect(!state.isProPurchasePresented)
    }

    @MainActor
    @Test func delayedUnlockAfterBackDoesNotSave() throws {
        let store = try projectStore()
        var creationCount = 0
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { _ in creationCount += 1 },
            draft: validDraft(type: .tops),
            step: .review
        )

        state.advance { .locked }
        state.moveBack()
        state.advance { .unlocked }

        #expect(state.step == .review)
        #expect(store.projects.isEmpty)
        #expect(creationCount == 0)
        #expect(!state.awaitingProCommit)
        #expect(!state.hasCommitted)
    }

    @MainActor
    @Test func unlockWhileDestinationIsActiveSavesExactlyOnce() throws {
        let store = try projectStore()
        var createdIDs: [UUID] = []
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { createdIDs.append($0) },
            draft: validDraft(type: .tops),
            step: .review
        )

        state.advance { .locked }
        #expect(state.isProPurchasePresented)
        state.advance { .unlocked }
        state.advance { .unlocked }
        state.advance { .unlocked }

        #expect(store.projects.count == 1)
        #expect(createdIDs.count == 1)
        #expect(store.project(id: try #require(createdIDs.first)) != nil)
        #expect(state.hasCommitted)
        #expect(!state.awaitingProCommit)
    }

    @MainActor
    @Test func repeatedLockedTapsAndDuplicateUnlocksDoNotDuplicate() throws {
        let store = try projectStore()
        var creationCount = 0
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { _ in creationCount += 1 },
            draft: validDraft(type: .other),
            step: .review
        )

        state.advance { .locked }
        state.advance { .locked }
        state.advance { .locked }
        #expect(store.projects.isEmpty)
        #expect(state.awaitingProCommit)

        state.advance { .unlocked }
        state.advance { .unlocked }

        #expect(store.projects.count == 1)
        #expect(creationCount == 1)
    }

    @MainActor
    @Test func savedProjectCountIsReevaluatedAtCommitTime() throws {
        let store = try projectStore(savedProjectCount: ProjectAccess.freeProjectLimit - 1)
        let originalCount = store.projects.count
        let concurrentProject = try project(type: .headwear, name: "Concurrent Project")
        var entitlementChecks = 0
        var creationCount = 0
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { _ in creationCount += 1 },
            draft: validDraft(type: .headwear),
            step: .review
        )

        state.advance {
            entitlementChecks += 1
            if entitlementChecks == 2 {
                #expect(store.add(concurrentProject))
            }
            return .locked
        }

        #expect(entitlementChecks == 2)
        #expect(store.projects.count == originalCount + 1)
        #expect(creationCount == 0)
        #expect(!state.hasCommitted)

        state.advance { .locked }
        #expect(state.isProPurchasePresented)
        #expect(state.awaitingProCommit)
        #expect(store.projects.count == originalCount + 1)
    }

    @MainActor
    @Test func persistenceFailureRetainsDraftAndCanRetry() throws {
        var shouldFail = true
        let store = try projectStore {
            if shouldFail {
                shouldFail = false
                throw TestError.saveFailed
            }
        }
        let draft = validDraft(type: .tops)
        var createdIDs: [UUID] = []
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { createdIDs.append($0) },
            draft: draft,
            step: .review
        )

        state.advance { .unlocked }
        #expect(store.projects.isEmpty)
        #expect(createdIDs.isEmpty)
        #expect(state.draft == draft)
        #expect(state.showSaveFailure)
        #expect(!state.isCommitting)
        #expect(!state.hasCommitted)
        #expect(store.issue?.kind == .save)

        state.acknowledgeSaveFailure()
        state.advance { .unlocked }
        let createdID = try #require(createdIDs.first)
        #expect(createdIDs.count == 1)
        #expect(store.projects.count == 1)
        #expect(store.project(id: createdID) != nil)
        #expect(state.hasCommitted)
        #expect(!state.showSaveFailure)
    }

    @MainActor
    @Test(arguments: [
        ProjectType.tops,
        ProjectType.bottoms,
        ProjectType.footwear,
        ProjectType.other,
    ])
    func editingExistingProProjectsNeverGates(_ type: ProjectType) throws {
        let store = try projectStore()
        let existing = try project(type: type, name: "Existing")
        #expect(store.add(existing))
        var draft = ProjectDraft(project: existing)
        draft.name = "Edited"
        var callbackIDs: [UUID] = []
        let state = CreateProjectFlowState(
            store: store,
            onCreated: { callbackIDs.append($0) },
            draft: draft,
            editingProject: existing,
            step: .review
        )

        state.advance { .locked }

        #expect(!state.isProPurchasePresented)
        #expect(!state.awaitingProCommit)
        #expect(callbackIDs == [existing.id])
        #expect(store.projects.count == 1)
        #expect(store.project(id: existing.id)?.name == "Edited")
    }

    @MainActor
    @Test func resultsNavigationOnlyReceivesPersistedProjectIDs() throws {
        let store = try projectStore()
        let library = ProjectLibraryState(store: store)
        let lockedState = CreateProjectFlowState(
            store: store,
            onCreated: library.projectCreated,
            draft: validDraft(type: .tops),
            step: .review
        )

        lockedState.advance { .locked }
        library.dismissProjectCreator()
        library.openCreatedProject()
        #expect(library.navigationPath.isEmpty)
        #expect(library.createdProjectID == nil)

        let unlockedState = CreateProjectFlowState(
            store: store,
            onCreated: library.projectCreated,
            draft: validDraft(type: .tops),
            step: .review
        )
        unlockedState.advance { .unlocked }
        let persistedID = try #require(library.createdProjectID)
        #expect(store.project(id: persistedID) != nil)

        library.openCreatedProject()
        #expect(library.navigationPath == [persistedID])
        #expect(library.createdProjectID == nil)
    }

    @Test func unlockedAccessHasNoPerTypeProMarkerSemantics() {
        for type in ProjectType.allCases {
            #expect(!ProjectAccess.requiresPro(
                type: type,
                savedProjectCount: 100,
                originalType: nil,
                isUnlocked: true
            ))
            let semanticWords = "\(type.label) \(type.description)"
                .lowercased()
                .split(whereSeparator: { !$0.isLetter })
            #expect(!semanticWords.contains("pro"))
        }
    }

    @MainActor
    @Test func proViewsConstructAtCompactAccessibilityLayout() throws {
        let proStore = StitchwiseProStore(
            entitlement: .locked,
            storefrontState: .unavailable("Test storefront"),
            startsTransactionListener: false
        )
        expectFinite(
            StitchwiseProView(context: .general)
                .environment(proStore),
            width: 320
        )
        expectFinite(
            StitchwiseProView(
                context: .project(type: .tops, projectLimitReached: true)
            )
            .environment(proStore),
            width: 320
        )
        expectFinite(ProBadge(), width: 120)
        for status in [
            (isUnlocked: false, isChecking: false),
            (isUnlocked: false, isChecking: true),
            (isUnlocked: true, isChecking: false),
        ] {
            expectFinite(
                StitchwiseProToolbarButton(
                    isUnlocked: status.isUnlocked,
                    isChecking: status.isChecking,
                    action: {}
                ),
                width: 120
            )
        }

        func coverEveryDeterministicPresentationState() throws {
            let contexts: [StitchwiseProContext] = [
                .general,
                .project(type: .tops, projectLimitReached: false),
                .project(type: .tops, projectLimitReached: true),
                .project(type: .headwear, projectLimitReached: false),
                .project(type: .headwear, projectLimitReached: true),
            ]
            let entitlementCases: [StitchwiseProEntitlement] = [
                .checking, .locked, .unlocked,
            ]
            let storefrontCases: [StitchwiseProStorefrontState] = [
                .loading, .available, .unavailable("Test storefront"),
            ]

            for entitlement in entitlementCases {
                for storefront in storefrontCases {
                    let store = StitchwiseProStore(
                        entitlement: entitlement,
                        storefrontState: storefront,
                        startsTransactionListener: false
                    )
                    for context in contexts {
                        expectFinite(
                            StitchwiseProView(context: context)
                                .environment(store),
                            width: 320
                        )
                    }
                }
            }

            let statusStore = StitchwiseProStore(
                entitlement: .locked,
                storefrontState: .unavailable("Test storefront"),
                startsTransactionListener: false
            )
            let statuses: [StitchwiseProPurchaseState] = [
                .pending,
                .restoring,
                .failure("Test failure"),
                .restored,
                .nothingToRestore,
            ]
            for status in statuses {
                statusStore.setPurchaseStateForTesting(status)
                expectFinite(
                    StitchwiseProView(context: .general)
                        .environment(statusStore),
                    width: 320
                )
            }

            expectFinite(
                StitchwiseProSheet(context: .general)
                    .environment(statusStore)
                    .frame(width: 320, height: 844),
                width: 320
            )
            expectFinite(
                StitchwiseProSheet(
                    context: .project(type: .tops, projectLimitReached: true),
                    onPresentationOutcome: { _ in }
                )
                .environment(statusStore)
                .frame(width: 320, height: 844),
                width: 320
            )

            for entitlement in entitlementCases {
                let store = StitchwiseProStore(
                    entitlement: entitlement,
                    storefrontState: .unavailable("Test storefront"),
                    startsTransactionListener: false
                )
                expectFinite(
                    SettingsView(version: "1.0")
                        .environment(store)
                        .frame(width: 320, height: 844),
                    width: 320
                )
                let settings = SettingsView(version: "1.0", proStore: store)
                switch entitlement {
                case .checking:
                    #expect(settings.proSubtitle == "Checking access")
                case .locked:
                    #expect(settings.proSubtitle == "One-time purchase. No subscription.")
                case .unlocked:
                    #expect(settings.proSubtitle == "Unlocked")
                }
            }

            let draftHolder = ProDraftHolder(validDraft(type: .headwear))
            expectFinite(
                CreateProjectIdentityStep(
                    draft: draftHolder.binding,
                    showsProTypeIndicators: true
                ),
                width: 320
            )

            let library = ProjectLibraryView(store: try projectStore())
            _ = library.settingsSheet()
            _ = library.proSheet()

            let sheet = StitchwiseProSheet(context: .general, dismissAction: {})
            _ = sheet.body
            sheet.close()
        }
        try coverEveryDeterministicPresentationState()
        expectFinite(
            SettingsView(version: "1.0 (1)")
                .environment(proStore)
                .frame(width: 320, height: 844),
            width: 320
        )

        let flowStore = try projectStore()
        expectFinite(
            ProjectLibraryView(store: flowStore)
                .environment(proStore)
                .frame(width: 320, height: 844),
            width: 320
        )
        let flowState = CreateProjectFlowState(
            store: flowStore,
            onCreated: { _ in },
            draft: validDraft(type: .tops),
            step: .review,
            isProPurchasePresented: true,
            awaitingProCommit: true
        )
        expectFinite(
            CreateProjectFlow(state: flowState)
                .environment(proStore)
                .frame(width: 320, height: 844),
            width: 320
        )
    }

    @MainActor
    private func projectStore(
        savedProjectCount: Int = 0,
        beforeSave: @escaping () throws -> Void = {}
    ) throws -> ProjectStore {
        let container = try ModelContainer(
            for: StoredProjectRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = ProjectStore(modelContainer: container, beforeSave: beforeSave)
        for index in 0..<savedProjectCount {
            #expect(store.add(try project(type: .headwear, name: "Saved \(index)")))
        }
        return store
    }

    private func validDraft(type: ProjectType) -> ProjectDraft {
        var draft = ProjectDraft()
        draft.name = "\(type.label) Project"
        draft.gaugeValues = GaugeFormValues(
            patternStitches: "20",
            patternRows: "24",
            yourStitches: "22",
            yourRows: "26"
        )
        draft.selectType(type)
        for kind in draft.measurementKinds {
            draft.measurementValues[kind] = "20"
        }
        return draft
    }

    private func project(type: ProjectType, name: String) throws -> KnittingProject {
        var draft = validDraft(type: type)
        draft.name = name
        return try #require(draft.makeProject())
    }

    @MainActor
    private func expectFinite<Content: View>(
        _ content: Content,
        width: CGFloat
    ) {
        let controller = UIHostingController(
            rootView: content.environment(\.dynamicTypeSize, .accessibility3)
        )
        controller.loadViewIfNeeded()
        let size = controller.view.sizeThatFits(
            CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        )
        controller.view.frame = CGRect(
            x: 0,
            y: 0,
            width: width,
            height: max(100, size.height)
        )
        controller.view.layoutIfNeeded()
        let viewName = String(describing: Content.self)
        #expect(size.width.isFinite && size.height.isFinite, "\(viewName): \(size)")
        #expect(size.width > 0 && size.height > 0, "\(viewName): \(size)")
    }

}

struct AccessCase: CustomTestStringConvertible {
    let type: ProjectType
    let saved: Int
    let original: ProjectType?
    let unlocked: Bool
    let requiresPro: Bool

    var testDescription: String {
        "\(type.rawValue)-saved\(saved)-original\(original?.rawValue ?? "new")-unlocked\(unlocked)"
    }

    init(
        _ type: ProjectType,
        saved: Int,
        original: ProjectType?,
        unlocked: Bool,
        requiresPro: Bool
    ) {
        self.type = type
        self.saved = saved
        self.original = original
        self.unlocked = unlocked
        self.requiresPro = requiresPro
    }
}

struct GateCase: CustomTestStringConvertible {
    let type: ProjectType
    let saved: Int

    var testDescription: String {
        "\(type.rawValue)-saved\(saved)"
    }

    init(_ type: ProjectType, saved: Int) {
        self.type = type
        self.saved = saved
    }
}

struct EntitlementCase: CustomTestStringConvertible {
    let entitlement: StitchwiseProEntitlement
    let isChecking: Bool
    let isUnlocked: Bool

    var testDescription: String {
        "\(entitlement)"
    }

    init(
        _ entitlement: StitchwiseProEntitlement,
        isChecking: Bool,
        isUnlocked: Bool
    ) {
        self.entitlement = entitlement
        self.isChecking = isChecking
        self.isUnlocked = isUnlocked
    }
}

@MainActor
private final class ProDraftHolder {
    var value: ProjectDraft

    var binding: Binding<ProjectDraft> {
        Binding(
            get: { self.value },
            set: { self.value = $0 }
        )
    }

    init(_ value: ProjectDraft) {
        self.value = value
    }
}

@MainActor
private final class EntitlementBox {
    var value: StitchwiseProEntitlement

    init(_ value: StitchwiseProEntitlement) {
        self.value = value
    }
}

private final class Counter: @unchecked Sendable {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

private enum TestError: Error {
    case saveFailed
    case purchaseFailed
}
