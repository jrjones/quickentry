import Foundation

/// Shell execution errors
enum ShellError: Error, LocalizedError {
    case executionFailed(command: String, exitCode: Int32, stderr: String)
    case commandNotFound(String)

    var errorDescription: String? {
        switch self {
        case let .executionFailed(command, exitCode, stderr):
            return "Command '\(command)' failed with exit code \(exitCode): \(stderr)"
        case let .commandNotFound(command):
            return "Command not found: \(command)"
        }
    }
}

/// Helper for executing shell commands
enum Shell {
    /// Execute a shell command and return stdout
    /// - Parameters:
    ///   - command: The command to execute
    ///   - arguments: Arguments to pass to the command
    /// - Returns: The stdout output as a string
    /// - Throws: ShellError if the command fails
    @discardableResult
    static func run(_ command: String, arguments: [String] = []) throws -> String {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
        let stdoutString = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stderrString = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            throw ShellError.executionFailed(
                command: ([command] + arguments).joined(separator: " "),
                exitCode: process.terminationStatus,
                stderr: stderrString
            )
        }

        return stdoutString
    }

    /// Execute osascript with JavaScript
    /// - Parameter script: The JavaScript code to execute
    /// - Returns: The output from the script
    /// - Throws: ShellError if execution fails
    static func runJavaScript(_ script: String) throws -> String {
        try run("osascript", arguments: ["-l", "JavaScript", "-e", script])
    }

    /// Check if we're in a git repository
    /// - Returns: True if current directory is within a git repo
    static func isInGitRepo() -> Bool {
        do {
            _ = try run("git", arguments: ["rev-parse", "--show-toplevel"])
            return true
        } catch {
            return false
        }
    }

    /// Get the remote origin URL for the current git repo
    /// - Returns: The remote URL or nil if not available
    static func getGitRemoteURL() -> String? {
        try? run("git", arguments: ["remote", "get-url", "origin"])
    }

    /// Parse a GitHub repo from a git remote URL
    /// - Parameter remoteURL: The git remote URL (SSH or HTTPS format)
    /// - Returns: Tuple of (owner, repo) or nil if not a GitHub URL
    static func parseGitHubRepo(from remoteURL: String) -> (owner: String, repo: String)? {
        // SSH format: git@github.com:owner/repo.git
        // HTTPS format: https://github.com/owner/repo.git
        let patterns = [
            #"github\.com[:/]([^/]+)/([^/.]+)"#,  // Matches both formats
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: remoteURL, range: NSRange(remoteURL.startIndex..., in: remoteURL)),
               let ownerRange = Range(match.range(at: 1), in: remoteURL),
               let repoRange = Range(match.range(at: 2), in: remoteURL)
            {
                let owner = String(remoteURL[ownerRange])
                var repo = String(remoteURL[repoRange])
                // Remove .git suffix if present
                if repo.hasSuffix(".git") {
                    repo = String(repo.dropLast(4))
                }
                return (owner, repo)
            }
        }

        return nil
    }
}
