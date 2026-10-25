import SwiftUI
import SwiftData
import UIKit

struct CompetingResponseView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Keys.competingResponse) private var response = Defaults.competingResponse
    @AppStorage(Keys.competingDuration) private var duration = Defaults.competingDuration

    @State private var remaining = Defaults.competingDuration
    @State private var running = false
    @State private var finished = false
    @State private var showResponsePicker = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Wenn du den Drang spürst – oder einfach zum Üben: Führe deine Gegenreaktion aus und halte sie, bis der Timer abgelaufen ist. Der Drang ebbt in dieser Zeit meist ab.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                timerRing

                controls

                responseCard

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        CardTitle(title: "Eine gute Gegenreaktion ist …", symbol: "checkmark.seal.fill", tint: Palette.practice)
                        Bullet("mit dem Kauen unvereinbar – die Hände sind „besetzt“.")
                        Bullet("unauffällig, damit du sie überall machen kannst.")
                        Bullet("etwa eine Minute lang durchzuhalten.")
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Gegenreaktion")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(ticker) { _ in tick() }
        .onAppear {
            if !running { remaining = duration }
        }
        .onChange(of: duration) { _, newDuration in
            if !running {
                finished = false
                remaining = newDuration
            }
        }
        .onChange(of: running) { _, isRunning in
            UIApplication.shared.isIdleTimerDisabled = isRunning
        }
        .onDisappear {
            running = false
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .sensoryFeedback(.success, trigger: finished) { _, newValue in newValue }
        .sensoryFeedback(.impact(weight: .light), trigger: running)
        .sheet(isPresented: $showResponsePicker) {
            ResponsePickerView()
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Bausteine

    private var progress: Double {
        if finished { return 1 }
        guard duration > 0 else { return 0 }
        return 1 - Double(remaining) / Double(duration)
    }

    private var timeString: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 18)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [Palette.practice, Palette.practiceDeep, Palette.practice], center: .center),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            VStack(spacing: 6) {
                if finished {
                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Palette.resist)
                    Text("Geschafft!")
                        .font(.title2.bold())
                } else {
                    Text(timeString)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                    Text(response)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
            }
        }
        .frame(width: 270, height: 270)
        .padding(.vertical, 8)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if finished {
                Button {
                    reset()
                } label: {
                    Label("Nochmal", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(Palette.practice)
                .controlSize(.large)
            } else {
                Button {
                    running.toggle()
                } label: {
                    Label(running ? "Pause" : (remaining == duration ? "Start" : "Weiter"),
                          systemImage: running ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(Palette.practice)
                .controlSize(.large)

                Button {
                    reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .disabled(remaining == duration && !running)
                .accessibilityLabel("Zurücksetzen")
            }
        }
    }

    private var responseCard: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Deine Gegenreaktion")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(response)
                        .font(.headline)
                    Text("Dauer: \(duration) Sekunden")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Ändern") {
                    showResponsePicker = true
                }
                .buttonStyle(.bordered)
                .disabled(running)
            }
        }
    }

    // MARK: - Logik

    private func tick() {
        guard running else { return }
        if remaining > 1 {
            withAnimation { remaining -= 1 }
        } else {
            remaining = 0
            running = false
            finished = true
            context.insert(PracticeSession(type: .competing, durationSeconds: duration))
            try? context.save()
        }
    }

    private func reset() {
        running = false
        finished = false
        remaining = duration
    }
}

// MARK: - Auswahl der Gegenreaktion

struct ResponsePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Keys.competingResponse) private var response = Defaults.competingResponse
    @AppStorage(Keys.competingDuration) private var duration = Defaults.competingDuration
    @State private var custom = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Vorschläge") {
                    ForEach(Defaults.competingResponses, id: \.self) { option in
                        Button {
                            response = option
                        } label: {
                            HStack {
                                Text(option)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if option == response {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Palette.practice)
                                }
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        TextField("Eigene Gegenreaktion", text: $custom)
                        Button("Übernehmen") {
                            let trimmed = custom.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                response = trimmed
                                custom = ""
                            }
                        }
                        .disabled(custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("Eigene")
                } footer: {
                    Text("Wähle etwas, das du auch in deinen typischen Situationen unauffällig machen kannst.")
                }

                Section("Dauer") {
                    Picker("Dauer", selection: $duration) {
                        Text("30 Sekunden").tag(30)
                        Text("1 Minute").tag(60)
                        Text("90 Sekunden").tag(90)
                        Text("2 Minuten").tag(120)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Gegenreaktion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Aufzählungspunkt

struct Bullet: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(Color.secondary)
                .frame(width: 5, height: 5)
                .offset(y: -3)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
