import Foundation

/// Every piece of user-facing copy in GovApp.
///
/// The app ships in Haitian Creole (Kreyòl). Views must not inline literals —
/// add them here so a translation pass only ever touches one file.
enum L10n {
    enum General {
        static let brand = "ayiti.io"
        static let repiblik = "Repiblik"
        static let ayiti = "Ayiti"
    }

    enum Welcome {
        static let signIn = "login"
        static let avatar = "Foto pwofil"
    }

    enum SignIn {
        static let title = "Bonjou, konekte isit la"
        static let hid = "Idantite Ayiti (HID)"
        static let pin = "Kòd sekrè (Pin)"
        static let submit = "Konekte"
        static let sessionID = "Session ID:"
        static let expiresIn = "Expires in:"
        static let copyright = "© 2026 ayiti.io from"
        static let working = "N ap verifye…"
    }

    enum Chat {
        static let assistant = "GOVTalk AI"
        static let composerPlaceholder = "what can i help you"
        static let send = "Voye"
        static let offline = "GOVTalk pa konekte. Tcheke sèvè ElloFive la."
        static let thinking = "GOVTalk ap reflechi…"
        static let signOut = "Dekonekte"

        /// Seeded locally when the screen opens; never comes from the model.
        static func greeting(_ name: String) -> String {
            name.isEmpty
                ? "Bonjou! Kijan m ka ede w jodi a?"
                : "Bonjou \(name)! Kijan m ka ede w jodi a?"
        }

        /// Prepended to every request so the model answers as GOVTalk rather
        /// than as ElloFive. Kept short — it is re-sent on every turn.
        static let systemPersona = """
        Ou se GOVTalk, asistan ofisyèl Repiblik Ayiti sou ayiti.io.
        Reponn an kreyòl ayisyen, kout epi klè.
        Pa janm envante enfòmasyon ofisyèl. Si ou pa konnen, di sa klèman epi \
        voye sitwayen an bay biwo ki konsène a.
        """
    }

    enum Failure {
        static let invalidCredentials = "HID oswa kòd sekrè a pa kòrèk."
        static let grantExpired = "Sesyon an fini. Tanpri rekòmanse."
        static let tooManyAttempts = "Twòp esè. Tann yon ti moman anvan ou eseye ankò."
        static let identityUnavailable = "Sèvis idantite a pa disponib kounye a."
        static let assistantUnavailable = "GOVTalk pa disponib kounye a."
        static let network = "Nou pa ka konekte ak rezo a. Tcheke koneksyon ou."
        static let canceled = "Ou anile koneksyon an."
    }
}
