import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HUTheme.space24) {
                Text("HUSTLE PROFILE")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(HUTheme.text)
                    .accessibilityIdentifier(HUID.profileRoot)

                Text("Notes come from moves you marked. Not from a personality test.")
                    .font(.body)
                    .foregroundStyle(HUTheme.muted)

                if model.profileObservations.isEmpty {
                    HUEmptyState(
                        title: "NO PATTERN YET",
                        detail: "Log whether a move worked. Two similar outcomes unlock a note."
                    )
                    .frame(minHeight: 120)
                } else {
                    ForEach(model.profileObservations) { note in
                        HUCard {
                            VStack(alignment: .leading, spacing: HUTheme.space8) {
                                Text(note.title)
                                    .font(.headline)
                                    .foregroundStyle(HUTheme.accent)
                                Text(note.detail)
                                    .font(.body)
                                    .foregroundStyle(HUTheme.text)
                                    .fixedSize(horizontal: false, vertical: true)
                                HUSectionHeader(title: "WHY WE SHOW THIS")
                                ForEach(Array(Set(note.samples)).sorted(), id: \.self) { sample in
                                    Text(sample)
                                        .font(.subheadline)
                                        .foregroundStyle(HUTheme.muted)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(note.title). \(note.detail)")
                    }
                }
            }
            .padding(HUTheme.space24)
        }
        .background(HUTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
