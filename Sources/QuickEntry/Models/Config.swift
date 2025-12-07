import Foundation
import TOMLKit

/// Errors that can occur when loading configuration
enum ConfigError: Error, CustomStringConvertible {
    case configFileNotFound(path: String)
    case parseError(underlying: Error)
    case missingRequired(field: String)

    var description: String {
        switch self {
        case .configFileNotFound(let path):
            return "Config file not found at \(path). Create it with required [obsidian] section."
        case .parseError(let error):
            return "Failed to parse config: \(error.localizedDescription)"
        case .missingRequired(let field):
            return "Missing required config field: \(field)"
        }
    }
}

/// Configuration for QuickEntry
struct Config: Sendable {
    let obsidian: ObsidianConfig
    let github: GitHubConfig

    struct ObsidianConfig: Sendable {
        let vault: String
        let vaultPath: String
        let inboxFolder: String
        let dailyNoteFolder: String  // e.g., "daily"
        let dailyNoteFormat: String  // e.g., "yyyy-MM-dd"
    }

    struct GitHubConfig: Sendable {
        let defaultOwner: String?
    }

    /// Config file path
    static let configPath = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".config/qe/config.toml")

    /// Load configuration from file
    /// - Throws: ConfigError if file missing or invalid
    static func load() throws -> Config {
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw ConfigError.configFileNotFound(path: configPath.path)
        }

        let contents: String
        let toml: TOMLTable
        do {
            contents = try String(contentsOf: configPath, encoding: .utf8)
            toml = try TOMLTable(string: contents)
        } catch {
            throw ConfigError.parseError(underlying: error)
        }

        return try parse(toml)
    }

    /// Parse TOML table into Config
    /// - Throws: ConfigError.missingRequired if required fields are absent
    private static func parse(_ toml: TOMLTable) throws -> Config {
        guard let obsidianTable = toml["obsidian"]?.table else {
            throw ConfigError.missingRequired(field: "[obsidian]")
        }

        guard let vault = obsidianTable["vault"]?.string else {
            throw ConfigError.missingRequired(field: "obsidian.vault")
        }

        guard let vaultPath = obsidianTable["vault_path"]?.string else {
            throw ConfigError.missingRequired(field: "obsidian.vault_path")
        }

        guard let inboxFolder = obsidianTable["inbox_folder"]?.string else {
            throw ConfigError.missingRequired(field: "obsidian.inbox_folder")
        }

        guard let dailyNoteFolder = obsidianTable["daily_note_folder"]?.string else {
            throw ConfigError.missingRequired(field: "obsidian.daily_note_folder")
        }

        guard let dailyNoteFormat = obsidianTable["daily_note_format"]?.string else {
            throw ConfigError.missingRequired(field: "obsidian.daily_note_format")
        }

        let obsidian = ObsidianConfig(
            vault: vault,
            vaultPath: vaultPath,
            inboxFolder: inboxFolder,
            dailyNoteFolder: dailyNoteFolder,
            dailyNoteFormat: dailyNoteFormat
        )

        // GitHub config is optional - no defaults, just read what's there
        let githubTable = toml["github"]?.table
        let github = GitHubConfig(
            defaultOwner: githubTable?["default_owner"]?.string
        )

        return Config(obsidian: obsidian, github: github)
    }
}
