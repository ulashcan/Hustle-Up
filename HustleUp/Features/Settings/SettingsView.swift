import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HUTheme.space24) {
                Text("SETTINGS")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(HUTheme.text)

                HUCard {
                    VStack(alignment: .leading, spacing: HUTheme.space12) {
                        HUSectionHeader(title: "PRIVACY")
                        Text("Screenshots are read on your device. We do not keep the image.")
                            .foregroundStyle(HUTheme.text)
                        Text("Situation text stays on this phone unless you later connect a live AI endpoint. We do not log conversations into analytics.")
                            .foregroundStyle(HUTheme.muted)
                    }
                    .font(.subheadline)
                }

                HUCard {
                    VStack(alignment: .leading, spacing: HUTheme.space12) {
                        HUSectionHeader(title: "PLAN")
                        Text(model.isPro ? "Pro preview on" : "Free")
                            .font(.headline)
                            .foregroundStyle(HUTheme.text)
                        if !model.isPro {
                            Text(model.remainingAnalysesDetail)
                                .foregroundStyle(HUTheme.muted)
                                .font(.subheadline)
                        }
                        #if DEBUG
                        Toggle("Pro preview (dev)", isOn: Binding(
                            get: { model.isPro },
                            set: { model.setProPreview($0) }
                        ))
                        .tint(HUTheme.accent)
                        .foregroundStyle(HUTheme.text)
                        Text("Purchases are not live. Product IDs are reserved: \(ProductCatalog.proMonthly). This switch only unlocks Pro on this device.")
                            .font(.caption)
                            .foregroundStyle(HUTheme.muted)
                        #else
                        Text("Purchases are not live. Three free analyses stay on this device.")
                            .font(.caption)
                            .foregroundStyle(HUTheme.muted)
                        #endif
                    }
                }

                HUButton(title: "DELETE LOCAL DATA", kind: .danger) {
                    confirmDelete = true
                }

                Text("HUSTLE UP 1.0. Make better moves.")
                    .font(.caption)
                    .foregroundStyle(HUTheme.muted)
            }
            .padding(HUTheme.space24)
        }
        .background(HUTheme.background.ignoresSafeArea())
        .accessibilityIdentifier(HUID.settings)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete everything on this device?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                model.deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Analyses, outcomes, counts, and the Pro preview flag go. Screenshots were never stored.")
        }
    }
}
