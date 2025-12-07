import Foundation

/// Service for creating tasks in OmniFocus
enum OmniFocusService {
    /// Create a task in OmniFocus inbox
    /// - Parameters:
    ///   - title: The task title
    ///   - note: Optional note content
    /// - Returns: The task ID
    /// - Throws: ShellError if OmniFocus automation fails
    static func createTask(title: String, note: String?) throws -> String {
        // Escape strings for JavaScript
        let escapedTitle = title.jsEscaped
        let escapedNote = note?.jsEscaped ?? ""

        let script = """
        (function() {
            const of = Application('OmniFocus');
            of.includeStandardAdditions = true;
            const doc = of.defaultDocument;
            const inbox = doc.inboxTasks;
            const task = of.Task({
                name: "\(escapedTitle)",
                note: "\(escapedNote)"
            });
            inbox.push(task);
            return task.id();
        })()
        """

        return try Shell.runJavaScript(script)
    }

    /// Generate OmniFocus URL for a task
    /// - Parameter taskID: The task ID
    /// - Returns: URL to open the task in OmniFocus
    static func taskURL(for taskID: String) -> String {
        "omnifocus:///task/\(taskID)"
    }
}

extension String {
    /// Escape string for use in JavaScript string literal
    var jsEscaped: String {
        self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
