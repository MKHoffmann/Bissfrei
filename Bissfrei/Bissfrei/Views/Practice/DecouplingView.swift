import SwiftUI
import SwiftData
import UIKit

struct DecouplingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BiteEvent.timestamp, order: .reverse) private var events: [BiteEvent]

    @AppStorage(Keys.decouplingReps) private var targetReps = Defaults.decouplingReps
    @AppStorage(Keys.decouplingInterval) private var interval = Defaults.decouplingInterval
    @AppStorage(Keys.decouplingTarget) private var target = Defaults.decouplingTarget

    @State private var running = false
    @State private var count = 0
    @State private var finished = false
    @State private var nextCue = Date.distantFuture
    @State private var showSteps = true

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                stepsCard

                cueCircle

                controls

                settingsCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Decoupling")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(ticker) { now in tick(now) }
        .onChange(of: running) { _, isRunning in
            UIApplication.shared.isIdleTimerDisabled = isRunning
        }
        .onDisappear {
            running = false
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: count) { _, newValue in newValue > 0 }
        .sensoryFeedback(.success, trigger: finished) { _, newValue in newValue }
    }

    // MARK: - Anleitung

    private var dominantHand: Hand? {
        let hands = events.filter { $0.kind == .bitten }.compactMap { $0.hand }
        guard !hands.isEmpty else { return nil }
        let left = hands.filter { $0 == .left }.count
        let right = hands.filter { $0 == .right }.count
        if left == right { return nil }
        return left > right ? .left : .right
    }

    private var stepsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation(.snappy) { showSteps.toggle() }
                } label: {
                    HStack {
                        CardTitle(title: "So geht's", symbol: "list.number", tint: Palette.resistDeep)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showSteps ? 0 : -90))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if showSteps {
                    StepRow(number: 1, text: "Starte die gewohnte Bewegung: Führe die Hand zügig Richtung Mund, als würdest du gleich kauen.")
                    StepRow(number: 2, text: "Kurz bevor die Finger den Mund erreichen, lenkst du die Bewegung abrupt um und berührst stattdessen kurz dein Ziel: \(target).")
                    StepRow(number: 3, text: "Tempo ist wichtig: Die Umlenkung soll schnell und flüssig sein, damit sich der neue Ablauf an den alten anhängt.")
                    StepRow(number: 4, text: "Übe mehrmals täglich ein paar Runden – auch ganz ohne Drang. Kommt ein Drang, nutzt du genau diese Bewegung.")

                    if let dominantHand {
                        Label("Du kaust laut deinen Einträgen meist mit der \(dominantHand == .left ? "linken" : "rechten") Hand – übe vor allem mit ihr.", systemImage: "hand.point.up.left.fill")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Palette.resistDeep)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }

    // MARK: - Takt-Kreis

    private var cueCircle: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: (running || finished) ? [Palette.resist, Palette.resistDeep] : [Color(.tertiarySystemFill), Color(.tertiarySystemFill)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: (running || finished) ? Palette.resistDeep.opacity(0.35) : .clear, radius: 20, y: 8)

            VStack(spacing: 6) {
                if finished {
                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                    Text("\(count) Wiederholungen")
                        .font(.headline)
                } else if running {
                    Text(count == 0 ? "Bereit …" : "Jetzt!")
                        .font(.title2.bold())
                    Text("\(count) / \(targetReps)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("Hand Richtung Mund → \(target)")
                        .font(.caption)
                        .opacity(0.9)
                } else {
                    Image(systemName: PracticeType.decoupling.symbol)
                        .font(.system(size: 44))
                        .foregroundStyle(Palette.resistDeep)
                    Text("\(targetReps) Wiederholungen")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Bei jedem Vibrieren eine Bewegung")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(running || finished ? Color.white : Color.primary)
            .padding(24)
        }
        .frame(width: 250, height: 250)
        .phaseAnimator([1.0, 1.1], trigger: count) { content, scale in
            content.scaleEffect(scale)
        } animation: { _ in
            .spring(response: 0.18, dampingFraction: 0.55)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                if running {
                    stop(save: count > 0)
                } else {
                    start()
                }
            } label: {
                Label(running ? "Beenden" : (finished ? "Neue Runde" : "Start"),
                      systemImage: running ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(Palette.resistDeep)
            .controlSize(.large)
        }
    }

    private var settingsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Stepper(value: $targetReps, in: 3...50) {
                    HStack {
                        Text("Wiederholungen")
                        Spacer()
                        Text("\(targetReps)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Takt")
                        Spacer()
                        Text(String(format: "alle %.1f s", interval))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $interval, in: 1.5...6, step: 0.5)
                        .tint(Palette.resistDeep)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ziel der Umlenkung")
                    FlowLayout {
                        ForEach(Defaults.decouplingTargets, id: \.self) { option in
                            Chip(title: option, isSelected: target == option, tint: Palette.resistDeep) {
                                target = option
                            }
                        }
                    }
                }
            }
            .disabled(running)
        }
    }

    // MARK: - Logik

    private func start() {
        count = 0
        finished = false
        running = true
        nextCue = Date().addingTimeInterval(1.5)
    }

    private func stop(save: Bool) {
        running = false
        nextCue = .distantFuture
        if save {
            finished = true
            context.insert(PracticeSession(type: .decoupling, repetitions: count))
            try? context.save()
        }
    }

    private func tick(_ now: Date) {
        guard running, now >= nextCue else { return }
        withAnimation(.snappy) { count += 1 }
        if count >= targetReps {
            // Letzte Bewegung noch ausführen lassen, dann abschließen.
            nextCue = .distantFuture
            DispatchQueue.main.asyncAfter(deadline: .now() + min(interval, 2.0)) {
                if running { stop(save: true) }
            }
        } else {
            nextCue = now.addingTimeInterval(interval)
        }
    }
}

private struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.footnote.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Palette.resistDeep.gradient, in: Circle())
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
