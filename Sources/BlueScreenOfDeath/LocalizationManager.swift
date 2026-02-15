import Foundation

/// Manages per-app language override for localization.
/// When set to "system", uses the system locale. Otherwise loads
/// strings from the specified language's .lproj bundle.
final class LocalizationManager {
    static let shared = LocalizationManager()

    /// All languages supported by the app, sorted by English name.
    /// Each entry: (code, nativeName, englishName)
    static let supportedLanguages: [(code: String, nativeName: String, englishName: String)] = [
        ("ar",      "العربية",        "Arabic"),
        ("bn",      "বাংলা",          "Bengali"),
        ("chr",     "ᏣᎳᎩ ᎦᏬᏂᎯᏍᏗ",  "Cherokee"),
        ("zh-Hans", "简体中文",        "Chinese (Simplified)"),
        ("zh-Hant", "繁體中文",        "Chinese (Traditional)"),
        ("nl",      "Nederlands",     "Dutch"),
        ("en",      "English",        "English"),
        ("eo",      "Esperanto",      "Esperanto"),
        ("fr",      "Français",       "French"),
        ("de",      "Deutsch",        "German"),
        ("hi",      "हिन्दी",           "Hindi"),
        ("id",      "Bahasa Indonesia","Indonesian"),
        ("it",      "Italiano",       "Italian"),
        ("ja",      "日本語",          "Japanese"),
        ("ko",      "한국어",          "Korean"),
        ("pl",      "Polski",         "Polish"),
        ("pt-BR",   "Português (BR)", "Portuguese (Brazil)"),
        ("ru",      "Русский",        "Russian"),
        ("es",      "Español",        "Spanish"),
        ("th",      "ภาษาไทย",        "Thai"),
        ("tr",      "Türkçe",         "Turkish"),
        ("uk",      "Українська",     "Ukrainian"),
        ("vi",      "Tiếng Việt",     "Vietnamese"),
    ]

    private var overrideBundle: Bundle?

    /// The current language code, "system" for system default, or "random" for random each activation.
    var currentLanguage: String {
        get { UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system" }
        set {
            UserDefaults.standard.set(newValue, forKey: "selectedLanguage")
            if newValue == "random" {
                loadRandomLanguage()
            } else {
                loadBundle(for: newValue)
            }
        }
    }

    /// Display name for the current language selection.
    var currentLanguageDisplayName: String {
        if currentLanguage == "system" {
            return string("language.system")
        }
        if currentLanguage == "random" {
            return string("language.random")
        }
        for lang in Self.supportedLanguages where lang.code == currentLanguage {
            return lang.nativeName
        }
        return currentLanguage
    }

    private init() {
        let lang = currentLanguage
        if lang == "random" {
            loadRandomLanguage()
        } else {
            loadBundle(for: lang)
        }
    }

    /// Pick a random language from the supported list and load its bundle.
    func loadRandomLanguage() {
        let code = Self.supportedLanguages.randomElement()!.code
        loadBundle(for: code)
    }

    private func loadBundle(for languageCode: String) {
        guard languageCode != "system" else {
            overrideBundle = nil
            return
        }

        // Try to find the .lproj in our module bundle.
        // SPM may lowercase directory names (e.g. zh-Hans -> zh-hans),
        // so try both the original code and its lowercased form.
        let candidates = [languageCode, languageCode.lowercased()]
        for candidate in candidates {
            if let path = Bundle.module.path(forResource: candidate, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                overrideBundle = bundle
                return
            }
        }
        // Fall back to base (English)
        overrideBundle = nil
    }

    /// Look up a localized string.
    func string(_ key: String) -> String {
        if let bundle = overrideBundle {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)
            // If the override bundle doesn't have the key, fall back to module bundle
            if value != key { return value }
        }
        return Bundle.module.localizedString(forKey: key, value: nil, table: nil)
    }

    /// Look up a localized format string and apply arguments.
    func string(_ key: String, _ args: CVarArg...) -> String {
        let format = string(key)
        return String(format: format, arguments: args)
    }
}

/// Convenience global function for localized string lookup.
func L(_ key: String) -> String {
    LocalizationManager.shared.string(key)
}

/// Convenience global function for localized format string lookup.
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = LocalizationManager.shared.string(key)
    return String(format: format, arguments: args)
}
