import SwiftUI
import UIKit

struct WelcomeView: View {
    @AppStorage(Keys.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image(systemName: "hand.raised.fingers.spread.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [Palette.practice, Palette.resistDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .padding(.top, 40)

                VStack(spacing: 8) {
                    Text("Willkommen bei Bissfrei")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("Nägelkauen verstehen und abgewöhnen – mit den Methoden, die in Studien am besten abschneiden.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 22) {
                    FeatureRow(
                        symbol: "hand.tap.fill",
                        tint: Palette.bite,
                        title: "Bemerken & erfassen",
                        text: "Ein Tipp, sobald du gekaut oder einem Drang widerstanden hast. Alle Details sind optional."
                    )
                    FeatureRow(
                        symbol: "chart.bar.xaxis",
                        tint: Palette.practice,
                        title: "Muster erkennen",
                        text: "Situationen, Gefühle, Hand und Tageszeit zeigen dir, wann es passiert."
                    )
                    FeatureRow(
                        symbol: "figure.mind.and.body",
                        tint: Palette.resist,
                        title: "Gezielt üben",
                        text: "Habit Reversal Training und Decoupling, angeleitet und mit Timer."
                    )
                    FeatureRow(
                        symbol: "lock.fill",
                        tint: .gray,
                        title: "Privat",
                        text: "Alle Daten bleiben auf deinem iPhone. Kein Konto, keine Cloud."
                    )
                }
                .padding(.horizontal, 4)

                Button {
                    hasOnboarded = true
                } label: {
                    Text("Los geht's")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding(.top, 8)

                Text("Bissfrei ersetzt keine Therapie. Wenn das Kauen dich stark belastet, kann eine Verhaltenstherapie helfen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 28)
        }
    }
}

private struct FeatureRow: View {
    let symbol: String
    let tint: Color
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
