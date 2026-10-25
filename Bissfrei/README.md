# Bissfrei

iOS-App (ab iOS 26) zum Erfassen und Abgewöhnen von Nägelkauen – mit Selbstbeobachtung, Habit Reversal Training (HRT) und Decoupling. Alle Daten bleiben lokal auf dem iPhone.

## Funktionen

- **Ein-Tipp-Erfassung:** Großer Knopf „Gerade gekaut“ und „Drang widerstanden“. Der Eintrag ist sofort gespeichert. Danach erscheint eine kleine Leiste: „Bewusst“ oder „In Gedanken“ antippen, Details öffnen oder rückgängig machen.
- **Eigene Situationen als Schnellwahl:** z. B. „Coding“ oder „Fernsehen“ direkt unter dem großen Knopf – ein Tipp erfasst „gekaut beim Coding“. Situationen lassen sich anlegen, umbenennen, sortieren und mit Symbol versehen.
- **Modi:** Eine Situation lässt sich als Modus starten (manuell, per Kurzbefehl/Automation oder automatisch über einen iOS-Fokus). Bissfrei misst die Zeit im Modus und ordnet Einträge ihm zu.
- **Risikomodell:** Schätzt aus Uhrzeit, Werktag/Wochenende und Modus, wie hoch dein Risiko gerade im Vergleich zu deinem Durchschnitt ist (ab 10 Bissen an 5 Tagen).
- **Warnungen:** Kurz vor deinen riskantesten Uhrzeiten und beim Start riskanter Modi, mit optionaler Nachfrage nach 30–60 Minuten. Unter „Einblicke“ siehst du, ob du nach Warnungen seltener kaust als erwartet.
- **Details pro Eintrag:** Zeitpunkt, bewusst vs. in Gedanken, Situation, Hand, Finger, Gefühl davor, Stärke des Drangs, freie Notiz.
- **Verlauf:** Nach Tagen gruppiert, filterbar, bearbeiten und löschen.
- **Einblicke:** Verlauf pro Tag, kritische Tageszeiten, häufigste Situationen und Gefühle, Hand & Finger, Anteil bewusst/in Gedanken mit passender Empfehlung, Risikoprofil nach Uhrzeit, Risiko nach Modus, Wirkung der Warnungen, Vergleich zum vorigen Zeitraum.
- **Gegenreaktion (HRT):** 1-Minuten-Timer mit wählbarer Gegenreaktion.
- **Decoupling:** Geführte Übung mit Vibrations-Takt, Wiederholungszähler und Hinweis auf deine häufigste Kau-Hand.
- **Wenn-Dann-Pläne** für Risikosituationen.
- **Erinnerungen:** Tägliche Übungs-Erinnerung und Achtsamkeits-Checks, direkt aus der Mitteilung erfassbar.
- **Kurzbefehle/Siri/Aktionstaste:** „Gekaut“ und „Widerstanden“ als App-Kurzbefehle, z. B. per Doppeltipp auf die iPhone-Rückseite.
- **CSV-Export** und Wissensseite mit Quellen.

## 1. Auf GitHub hochladen

1. Auf github.com ein neues Repository anlegen, z. B. `bissfrei`. **Öffentlich** ist empfohlen: Dann sind die macOS-Builds kostenlos und ohne Minutenlimit. Im Repo liegt nur Code, keine persönlichen Daten.
2. Im entpackten Ordner (der versteckte Ordner `.github` muss mit hochgeladen werden):

```bash
cd Bissfrei
git init -b main
git add .
git commit -m "Bissfrei 1.0"
git remote add origin https://github.com/DEIN-NAME/bissfrei.git
git push -u origin main
```

## 2. Bauen lassen

Jeder Push auf `main` startet automatisch den Build (Reiter **Actions**, Workflow „iOS-App bauen“, ca. 5–10 Minuten). Manuell starten: Actions › iOS-App bauen › **Run workflow**.

- **Erfolgreich:** Die Datei `Bissfrei.ipa` liegt unter **Releases › ios-build**. Diese Seite kannst du direkt auf dem iPhone in Safari öffnen.
- **Fehlgeschlagen:** Auf der Übersichtsseite des Laufs steht eine Liste der Fehler. Diese Zeilen in den Chat mit Claude kopieren, du bekommst korrigierte Dateien zurück.

## 3. SideStore einrichten (einmalig, mit Linux)

SideStore signiert die App mit deiner kostenlosen Apple-ID direkt auf dem iPhone. Die offizielle Anleitung: https://docs.sidestore.io

Kurzfassung:

1. Unter Linux `usbmuxd` installieren (oft schon vorhanden), z. B. `sudo apt install usbmuxd`.
2. **iloader** von https://iloader.app bzw. https://github.com/nab138/iloader installieren.
3. iPhone per USB anschließen, entsperren und „Vertrauen“ bestätigen.
4. In iloader mit deiner Apple-ID anmelden und **SideStore** installieren. iloader legt dabei auch die nötige Pairing-Datei ab.
5. Auf dem iPhone den **Entwicklermodus** aktivieren: Einstellungen › Datenschutz & Sicherheit › Entwicklermodus (das iPhone startet neu).
6. Die VPN-App einrichten, die die SideStore-Anleitung nennt. Sie muss beim Installieren und Auffrischen aktiv sein.
7. SideStore öffnen und mit derselben Apple-ID anmelden.

## 4. Bissfrei installieren

1. Auf dem iPhone in Safari `github.com/DEIN-NAME/bissfrei/releases` öffnen und `Bissfrei.ipa` laden.
2. In SideStore auf **Meine Apps › +** tippen und die IPA aus „Downloads“ wählen (oder die Datei per Teilen-Menü an SideStore senden).

Mit einer kostenlosen Apple-ID gilt die Signatur **7 Tage**. Vorher in SideStore auf „Auffrischen“ tippen (VPN an). Deine Daten bleiben beim Auffrischen und bei Updates erhalten, solange du die App nicht löschst.

## Modi automatisch starten

- **Mit iOS-Fokus:** Einstellungen › Fokus › z. B. „Arbeiten“ › Fokusfilter › „Filter hinzufügen“ › Bissfrei › Modus wählen (z. B. Coding). Startet der Fokus, startet der Modus, endet der Fokus, endet auch der Modus. Ein manuell gestarteter Modus wird dabei nicht beendet.
- **Mit Kurzbefehl-Automationen:** In der Kurzbefehle-App unter „Automation“ z. B. „Wenn Xcode geöffnet wird → Bissfrei-Modus starten (Coding)“.
- **Risiko-Warnungen** in Bissfrei unter Einstellungen › Risiko-Warnungen einschalten.

## 5. Updates

Code ändern, pushen, neue IPA aus „Releases“ laden und in SideStore installieren. Sie ersetzt die alte Version, die Daten bleiben.

## Technik

- SwiftUI, SwiftData, Swift Charts, App Intents, lokale Mitteilungen
- Das Xcode-Projekt wird im Build aus `project.yml` mit [XcodeGen](https://github.com/yonaskolb/XcodeGen) erzeugt, deshalb liegt keine `.xcodeproj` im Repo.
- Der Workflow baut unsigniert (`CODE_SIGNING_ALLOWED=NO`). SideStore übernimmt das Signieren.

## Hinweis

Bissfrei ist eine Selbsthilfe-App und ersetzt keine ärztliche oder psychotherapeutische Behandlung.
