import Foundation

/// Parses raw input text into structured ParsedInput
enum InputParser {
    /// URL regex pattern - matches any URL scheme (http://, https://, omnifocus://, etc.)
    private static let urlPattern = #"\S+://\S+"#

    /// Parse raw text input into title, body, and optional URL
    /// - Parameter text: The raw input text (may contain newlines and URL)
    /// - Returns: Structured ParsedInput with extracted components
    static func parse(_ text: String) -> ParsedInput {
        var workingText = text
        var extractedURL: URL?

        // Extract URL if present
        if let urlRange = workingText.range(of: urlPattern, options: .regularExpression) {
            let urlString = String(workingText[urlRange])
            extractedURL = URL(string: urlString)
            // Remove URL from text
            workingText.removeSubrange(urlRange)
            // Clean up extra whitespace left behind
            workingText = workingText
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespaces)
        }

        // Split on first newline for title/body
        let lines = workingText.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)

        let title = String(lines.first ?? "").trimmingCharacters(in: .whitespaces)
        let body: String? = lines.count > 1
            ? String(lines[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            : nil

        return ParsedInput(
            title: title.isEmpty ? "Untitled" : title,
            body: body?.isEmpty == true ? nil : body,
            url: extractedURL
        )
    }
}
