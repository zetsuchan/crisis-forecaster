import AppIntents

/// Registers the spoken phrases so the patient can invoke both intents from Siri
/// and the lock screen without opening the app first.
struct CrisisForecasterShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CrisisRiskIntent(),
            phrases: [
                "What's my crisis risk this week in \(.applicationName)",
                "Check my crisis risk in \(.applicationName)",
                "\(.applicationName) crisis risk",
            ],
            shortTitle: "Crisis risk",
            systemImageName: "waveform.path.ecg"
        )
        AppShortcut(
            intent: ShowPassportIntent(),
            phrases: [
                "Show my sickle cell passport in \(.applicationName)",
                "Open my Emergency Passport in \(.applicationName)",
                "\(.applicationName) passport",
            ],
            shortTitle: "Passport",
            systemImageName: "cross.case"
        )
    }
}
