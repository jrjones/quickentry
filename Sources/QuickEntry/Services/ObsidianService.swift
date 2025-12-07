import Foundation

/// Errors specific to Obsidian operations
enum ObsidianError: Error, CustomStringConvertible {
    case dailyNoteNotFound(path: String)
    case noFilesToClean

    var description: String {
        switch self {
        case .dailyNoteNotFound(let path):
            return "Daily note not found at \(path). Create it first."
        case .noFilesToClean:
            return "No QuickEntry notes found in inbox."
        }
    }
}

/// Result of cleaning inbox
struct CleanResult {
    let movedCount: Int
    let files: [String]
    let dailyNotePath: String
}

/// Service for creating notes in Obsidian
enum ObsidianService {
    /// Pattern for QuickEntry-created files: yyyy-MM-dd-HHmmss.md
    private static let quickEntryPattern = #"^\d{4}-\d{2}-\d{2}-\d{6}\.md$"#

    /// Extract time from filename (yyyy-MM-dd-HHmmss.md) and format as "5:29pm"
    private static func formatTimeFromFilename(_ filename: String) -> String {
        // Extract HHmmss from filename like "2025-12-07-172933.md"
        let basename = (filename as NSString).deletingPathExtension
        let parts = basename.split(separator: "-")
        guard parts.count == 4, let timePart = parts.last, timePart.count == 6 else {
            return "?"
        }

        let hour = Int(timePart.prefix(2)) ?? 0
        let minute = Int(timePart.dropFirst(2).prefix(2)) ?? 0

        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let ampm = hour < 12 ? "am" : "pm"

        return "\(hour12):\(String(format: "%02d", minute))\(ampm)"
    }
    /// Create an inbox note in Obsidian vault
    /// - Parameters:
    ///   - content: The note content
    ///   - url: Optional URL to format as markdown link
    ///   - config: Configuration with vault info
    /// - Returns: Obsidian URL to the created note
    /// - Throws: If file creation fails
    static func createInboxNote(content: String, url: URL?, config: Config) throws -> String {
        let vaultPath = (config.obsidian.vaultPath as NSString).expandingTildeInPath
        let inboxPath = (vaultPath as NSString).appendingPathComponent(config.obsidian.inboxFolder)

        // Ensure inbox folder exists
        try FileManager.default.createDirectory(atPath: inboxPath, withIntermediateDirectories: true)

        // Generate timestamped filename
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "\(timestamp).md"
        let filePath = (inboxPath as NSString).appendingPathComponent(filename)

        // Format content with URL if present
        var finalContent = content
        if let url = url {
            let linkText = formatURLAsMarkdownLink(url)
            finalContent += "\n\n\(linkText)"
        }

        // Write file
        try finalContent.write(toFile: filePath, atomically: true, encoding: .utf8)

        // Return Obsidian URL
        let encodedVault = config.obsidian.vault.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? config.obsidian.vault
        let encodedFile = "\(config.obsidian.inboxFolder)/\(filename)"
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename

        return "obsidian://open?vault=\(encodedVault)&file=\(encodedFile)"
    }

    /// Format URL as markdown link with domain (excluding TLD) as text
    /// Example: https://developer.apple.com/docs → [developer.apple](https://developer.apple.com/docs)
    private static func formatURLAsMarkdownLink(_ url: URL) -> String {
        guard let host = url.host else {
            return url.absoluteString
        }

        // Split host into parts and remove TLD
        let parts = host.split(separator: ".")
        let domainWithoutTLD: String
        if parts.count > 1 {
            // Remove last part (TLD) and join with dots
            domainWithoutTLD = parts.dropLast().joined(separator: ".")
        } else {
            domainWithoutTLD = host
        }

        return "[\(domainWithoutTLD)](\(url.absoluteString))"
    }

    /// Clean inbox by appending QuickEntry notes to daily note
    /// - Parameters:
    ///   - config: Configuration with vault info
    ///   - dryRun: If true, don't actually modify files
    /// - Returns: Result with count and file list
    /// - Throws: If daily note doesn't exist or file operations fail
    static func cleanInbox(config: Config, dryRun: Bool) throws -> CleanResult {
        let vaultPath = (config.obsidian.vaultPath as NSString).expandingTildeInPath
        let inboxPath = (vaultPath as NSString).appendingPathComponent(config.obsidian.inboxFolder)

        // Build daily note path
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = config.obsidian.dailyNoteFormat
        let todayString = dateFormatter.string(from: Date())
        let dailyNotePath = (vaultPath as NSString)
            .appendingPathComponent(config.obsidian.dailyNoteFolder)
            .appending("/\(todayString).md")

        // Verify daily note exists
        guard FileManager.default.fileExists(atPath: dailyNotePath) else {
            throw ObsidianError.dailyNoteNotFound(path: dailyNotePath)
        }

        // Find QuickEntry files in inbox
        let fileManager = FileManager.default
        let inboxContents = try fileManager.contentsOfDirectory(atPath: inboxPath)
        let quickEntryFiles = inboxContents.filter { filename in
            filename.range(of: quickEntryPattern, options: .regularExpression) != nil
        }.sorted()

        if quickEntryFiles.isEmpty {
            return CleanResult(movedCount: 0, files: [], dailyNotePath: dailyNotePath)
        }

        if dryRun {
            return CleanResult(movedCount: quickEntryFiles.count, files: quickEntryFiles, dailyNotePath: dailyNotePath)
        }

        // Read all inbox file contents
        var contentToAppend = ""
        for filename in quickEntryFiles {
            let filePath = (inboxPath as NSString).appendingPathComponent(filename)
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let time = formatTimeFromFilename(filename)
            contentToAppend += "\n - QE \(time) - \(content)"
        }

        // Append to daily note
        let existingContent = try String(contentsOfFile: dailyNotePath, encoding: .utf8)
        let newContent = existingContent + contentToAppend
        try newContent.write(toFile: dailyNotePath, atomically: true, encoding: .utf8)

        // Delete inbox files
        for filename in quickEntryFiles {
            let filePath = (inboxPath as NSString).appendingPathComponent(filename)
            try fileManager.removeItem(atPath: filePath)
        }

        return CleanResult(movedCount: quickEntryFiles.count, files: quickEntryFiles, dailyNotePath: dailyNotePath)
    }
}
