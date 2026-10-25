import SwiftUI
import UIKit

// MARK: - Hilfreiche Maßnahmen (Stimuluskontrolle & Alltag)

struct TipsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                TipCard(
                    symbol: "scissors",
                    tint: Palette.bite,
                    title: "Nägel kurz und glatt halten",
                    text: "Feile Kanten glatt und pflege Niednägel und Nagelhaut. Was nicht hakt, lädt weniger zum Kauen ein – besonders wichtig, wenn du oft bewusst kaust."
                )
                TipCard(
                    symbol: "hand.raised.circle.fill",
                    tint: Palette.practice,
                    title: "Hände beschäftigen",
                    text: "Halte in Risikosituationen etwas in der Hand: Stressball, Fidget-Spielzeug, Stift. Leg es bewusst dorthin, wo es oft passiert – auf den Schreibtisch, neben das Sofa."
                )
                TipCard(
                    symbol: "bandage.fill",
                    tint: .orange,
                    title: "Barrieren nutzen",
                    text: "Pflaster auf den Lieblingsfingern, Handschuhe beim Fernsehen oder Nagellack machen das Kauen schwerer und dich aufmerksamer."
                )
                TipCard(
                    symbol: "drop.fill",
                    tint: .yellow,
                    title: "Bitterlack als Erinnerung",
                    text: "Bitterer Nagellack ist günstig und verbreitet. Sieh ihn als Wecker, der dich auf das Kauen aufmerksam macht – kombiniert mit Gegenreaktion oder Decoupling wirkt er besser als allein."
                )
                TipCard(
                    symbol: "iphone.radiowaves.left.and.right",
                    tint: Palette.resistDeep,
                    title: "Schneller erfassen",
                    text: "In der Kurzbefehle-App findest du „Gekaut“ und „Widerstanden“. Leg einen davon auf die Aktionstaste oder auf „Auf Rückseite tippen“ (Einstellungen › Bedienungshilfen › Tippen). Dann reicht ein Doppeltipp auf die Rückseite."
                )
                TipCard(
                    symbol: "person.2.fill",
                    tint: .pink,
                    title: "Jemanden einweihen",
                    text: "Soziale Unterstützung ist Teil des Habit Reversal Trainings: Eine vertraute Person darf dich freundlich hinweisen und deine Fortschritte loben."
                )
                TipCard(
                    symbol: "heart.fill",
                    tint: .red,
                    title: "Freundlich mit dir bleiben",
                    text: "Rückfälle sind normal. Scham und Selbstkritik erhöhen eher die Anspannung – und damit den Drang. Jeder ehrliche Eintrag ist ein Schritt nach vorn."
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Hilfreiche Maßnahmen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TipCard: View {
    let symbol: String
    let tint: Color
    let title: String
    let text: String

    var body: some View {
        Card {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Wissen

struct KnowledgeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                KnowledgeCard(
                    title: "Was ist Nägelkauen?",
                    symbol: "info.circle.fill",
                    tint: .gray,
                    paragraphs: [
                        "Nägelkauen (Onychophagie) zählt zu den körperbezogenen repetitiven Verhaltensweisen (BFRB), wie auch Haareausreißen oder Hautzupfen. Es ist sehr verbreitet und hat nichts mit fehlender Willenskraft zu tun.",
                        "Oft läuft es automatisch ab – beim Lesen, am Bildschirm, bei Stress oder Langeweile. Manchmal passiert es auch bewusst, etwa wegen einer rauen Kante."
                    ]
                )
                KnowledgeCard(
                    title: "1. Selbstbeobachtung",
                    symbol: "eye.fill",
                    tint: Palette.bite,
                    paragraphs: [
                        "Wer ehrlich protokolliert, wann, wo und in welcher Stimmung es passiert, bemerkt den Drang mit der Zeit früher. Das ist die Grundlage aller weiteren Schritte – und genau das macht der große Knopf auf „Heute“."
                    ]
                )
                KnowledgeCard(
                    title: "2. Habit Reversal Training (HRT)",
                    symbol: PracticeType.competing.symbol,
                    tint: Palette.practice,
                    paragraphs: [
                        "HRT hat in Studien zum Nägelkauen die beste und konsistenteste Evidenz. Es besteht aus Wahrnehmungstraining (Auslöser und Vorwarnzeichen erkennen), einer Gegenreaktion (etwa eine Minute lang etwas tun, das mit Kauen unvereinbar ist) und oft Entspannung sowie sozialer Unterstützung.",
                        "Üblicherweise leitet eine Therapeutin oder ein Therapeut HRT an; als Selbsthilfe umgesetzt zeigte es in Studien ebenfalls Wirkung."
                    ]
                )
                KnowledgeCard(
                    title: "3. Decoupling",
                    symbol: PracticeType.decoupling.symbol,
                    tint: Palette.resistDeep,
                    paragraphs: [
                        "Decoupling wurde am Universitätsklinikum Hamburg-Eppendorf entwickelt. Statt die Bewegung zu unterdrücken, wird sie kurz vor dem Mund schnell umgelenkt. So „entkoppelt“ sich der Ablauf vom Kauen.",
                        "In kontrollierten Studien wirkte Decoupling als Selbsthilfe, in einem direkten Vergleich schnitt es sogar etwas besser ab als HRT. Beide Methoden lassen sich gut kombinieren."
                    ]
                )
                KnowledgeCard(
                    title: "Weniger gut belegt",
                    symbol: "questionmark.circle.fill",
                    tint: .orange,
                    paragraphs: [
                        "Bitterlack ist beliebt, aber kaum systematisch untersucht – am sinnvollsten als Erinnerungshilfe. Für N-Acetylcystein (NAC) gibt es nur eine kleine Studie mit Kindern und Jugendlichen mit kurzfristigem Effekt. Kein Medikament ist für diese Verhaltensweisen zugelassen."
                    ]
                )
                KnowledgeCard(
                    title: "Wann professionelle Hilfe?",
                    symbol: "cross.case.fill",
                    tint: .red,
                    paragraphs: [
                        "Wenn das Kauen zu Entzündungen, Schmerzen oder starkem Leidensdruck führt oder sich trotz Üben nichts bessert, kann eine Verhaltenstherapie mit HRT helfen. Bissfrei ist eine Selbsthilfe-App und ersetzt keine Behandlung."
                    ]
                )
                KnowledgeCard(
                    title: "Wie Bissfrei dein Risiko schätzt",
                    symbol: "waveform.path.ecg",
                    tint: Palette.biteDeep,
                    paragraphs: [
                        "Bissfrei zählt, wie oft du pro Stunde kaust – getrennt nach Uhrzeit, Werktag/Wochenende und Modus – und vergleicht das mit deinem Durchschnitt. Bei Modi zählt die tatsächlich darin verbrachte Zeit: 20 Bisse in 40 Stunden Coding sind etwas anderes als 20 Bisse in 5 Stunden.",
                        "Seltene Kombinationen werden zum Durchschnitt hin geglättet, damit einzelne Ausreißer keine Fehlalarme auslösen. Grundlage sind die letzten 60 Tage, das Modell passt sich also an, wenn du Fortschritte machst.",
                        "Warnungen im richtigen Moment sind im Kern Wahrnehmungstraining – der erste Baustein von HRT. Ob sie dir helfen, zeigt die Auswertung unter „Einblicke“."
                    ]
                )

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        CardTitle(title: "Quellen", symbol: "books.vertical.fill", tint: .gray)
                        if let url = URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC9158250/") {
                            Link("Head-to-Head-Vergleich: HRT, Decoupling, Decoupling in sensu (2021)", destination: url)
                        }
                        if let url = URL(string: "https://link.springer.com/article/10.1007/s10608-022-10334-9") {
                            Link("Kombination der Selbsthilfe-Techniken (2022)", destination: url)
                        }
                        if let url = URL(string: "https://repositori.uvic-ucc.cat/handle/10854/180495") {
                            Link("Scoping Review: 21 RCTs zu Onychophagie (2025)", destination: url)
                        }
                        if let url = URL(string: "https://www.uke.de/decoupling") {
                            Link("UKE Hamburg: Decoupling", destination: url)
                        }
                    }
                    .font(.subheadline)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("So funktioniert's")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct KnowledgeCard: View {
    let title: String
    let symbol: String
    let tint: Color
    let paragraphs: [String]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                CardTitle(title: title, symbol: symbol, tint: tint)
                ForEach(paragraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
