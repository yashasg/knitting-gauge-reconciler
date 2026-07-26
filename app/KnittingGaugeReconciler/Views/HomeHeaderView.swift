import SwiftUI

// MARK: - AboutHelpToolbarButton

struct AboutHelpToolbarButton: View {
    @Binding private var state: AboutHelpState

    init(state: Binding<AboutHelpState>) {
        _state = state
    }

    func open() {
        state.open()
    }

    var body: some View {
        Button(action: open) {
            Image(systemName: "questionmark.circle")
                .font(.satoshiBody.weight(.medium))
                .foregroundStyle(AppTheme.sage)
                .frame(
                    minWidth: Sizing.minimumTouchTarget,
                    minHeight: Sizing.minimumTouchTarget
                )
                .contentShape(Rectangle())
        }
        .accessibilityLabel(AboutHelpContract.openLabel)
        .accessibilityHint(AboutHelpContract.openHint)
    }
}

struct SettingsToolbarButton: View {
    @Binding private var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        _isPresented = isPresented
    }

    func open() {
        isPresented = true
    }

    var body: some View {
        Button(action: open) {
            Image(systemName: "gearshape")
                .font(.system(.title3, design: .default, weight: .bold))
                .foregroundStyle(AppTheme.sage)
                .frame(
                    minWidth: Sizing.minimumTouchTarget,
                    minHeight: Sizing.minimumTouchTarget
                )
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens Stitchwise settings")
    }
}

struct StitchwiseProToolbarButton: View {
    let isUnlocked: Bool
    let isChecking: Bool
    let action: () -> Void

    var body: some View {
        Button("Pro", action: action)
            .font(.satoshiHeadline.weight(.bold))
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .tint(AppTheme.terracotta)
            .frame(
                minWidth: Sizing.minimumTouchTarget,
                minHeight: Sizing.minimumTouchTarget
            )
            .accessibilityLabel("Stitchwise Pro")
            .accessibilityHint("Opens Stitchwise Pro details")
            .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: Text {
        if isChecking {
            Text("Checking")
        } else if isUnlocked {
            Text("Unlocked")
        } else {
            Text("")
        }
    }
}

enum SettingsRoute: Hashable {
    case pro
    case about
    case privacy
}

struct SettingsView: View {
    static let proTitle = "Stitchwise Pro"

    @Environment(\.dismiss) private var dismiss
    @Environment(StitchwiseProStore.self) private var proStore
    private let version: String
    private let proStoreOverride: StitchwiseProStore?

    init(
        version: String = Self.currentVersion,
        proStore: StitchwiseProStore? = nil
    ) {
        self.version = version
        proStoreOverride = proStore
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink(value: SettingsRoute.pro) {
                        Label {
                            VStack(alignment: .leading, spacing: Spacing.hairline) {
                                Text(Self.proTitle)
                                Text(proSubtitle)
                                    .font(.satoshiCaption)
                                    .foregroundStyle(AppTheme.muted)
                            }
                        } icon: {
                            Image(systemName: "sparkles")
                                .foregroundStyle(AppTheme.sage)
                        }
                    }
                }

                Section("Information") {
                    NavigationLink("About Stitchwise", value: SettingsRoute.about)
                    NavigationLink("Privacy", value: SettingsRoute.privacy)
                }

                Section("App") {
                    LabeledContent("Version", value: version)
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsRoute.self, destination: destination)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .tint(AppTheme.sage)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        "Done",
                        systemImage: "checkmark",
                        action: dismiss.callAsFunction
                    )
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Done")
                }
            }
        }
    }

    @ViewBuilder
    func destination(_ route: SettingsRoute) -> some View {
        switch route {
        case .pro:
            StitchwiseProView(context: .general)
        case .about:
            AboutSettingsView()
        case .privacy:
            PrivacySettingsView()
        }
    }

    var proSubtitle: String {
        if activeProStore.isChecking {
            "Checking access"
        } else if activeProStore.isUnlocked {
            "Unlocked"
        } else {
            "One-time purchase. No subscription."
        }
    }

    private var activeProStore: StitchwiseProStore {
        proStoreOverride ?? proStore
    }

    static var currentVersion: String {
        versionText(
            version: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String,
            build: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleVersion"
            ) as? String
        )
    }

    static func versionText(version: String?, build: String?) -> String {
        switch (version, build) {
        case let (version?, build?):
            "\(version) (\(build))"
        case let (version?, nil):
            version
        case let (nil, build?):
            "Build \(build)"
        case (nil, nil):
            "Unavailable"
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.roomy) {
                Text(AboutHelpContract.explanation)
                Text(AboutHelpContract.math)
                Text(AboutHelpContract.scope)
                    .font(.satoshiBody.weight(.semibold))
                    .foregroundStyle(AppTheme.warningText)
                    .padding(Spacing.margin)
                    .background(AppTheme.warningBackground)
                    .clipShape(.rect(cornerRadius: Radius.extraSmall))
                Text(AboutHelpContract.nonAffiliation)
                    .font(.satoshiFootnote.italic())
                    .foregroundStyle(AppTheme.muted)
            }
            .font(.satoshiBody)
            .foregroundStyle(AppTheme.ink)
            .padding(Spacing.margin)
        }
        .navigationTitle("About Stitchwise")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.background)
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        ScrollView {
            Text(AboutHelpContract.privacy)
                .font(.satoshiBody)
                .foregroundStyle(AppTheme.ink)
                .padding(Spacing.margin)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.background)
    }
}
