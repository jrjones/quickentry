import Foundation

/// Service for creating GitHub issues
enum GitHubService {
    /// Cache file for repo list
    private static let cacheURL = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".cache/qe/repos.json")

    /// Repo info from GitHub
    struct Repo: Codable, Sendable {
        let name: String
        let nameWithOwner: String
    }

    /// Create a GitHub issue
    /// - Parameters:
    ///   - repo: The repo in owner/name format
    ///   - title: Issue title
    ///   - body: Optional issue body
    /// - Returns: URL to the created issue
    /// - Throws: ShellError if gh CLI fails
    static func createIssue(repo: String, title: String, body: String?) throws -> String {
        var args = ["issue", "create", "--repo", repo, "--title", title]
        if let body = body, !body.isEmpty {
            args += ["--body", body]
        } else {
            args += ["--body", ""]
        }

        let output = try Shell.run("gh", arguments: args)

        // gh issue create outputs the URL on success
        return output
    }

    /// Resolve a repo name to full owner/repo format
    /// - Parameters:
    ///   - name: Short repo name (e.g., "neodeck")
    ///   - config: Config with default owner
    /// - Returns: Full repo path (e.g., "jrjones/neodeck")
    /// - Throws: If repo cannot be resolved
    static func resolveRepo(_ name: String, config: Config) throws -> String {
        // If already in owner/repo format, return as-is
        if name.contains("/") {
            return name
        }

        // Try to find in cached repos
        let repos = try loadOrRefreshCache()
        let matches = repos.filter { $0.name.lowercased() == name.lowercased() }

        switch matches.count {
        case 0:
            throw RepoError.notFound(name)
        case 1:
            return matches[0].nameWithOwner
        default:
            // Multiple matches - prefer default owner if configured
            if let defaultOwner = config.github.defaultOwner,
               let preferred = matches.first(where: { $0.nameWithOwner.hasPrefix(defaultOwner + "/") })
            {
                return preferred.nameWithOwner
            }
            // Otherwise show options (for now, throw error with options)
            let options = matches.map(\.nameWithOwner).joined(separator: ", ")
            throw RepoError.ambiguous(name, options: options)
        }
    }

    /// Load cached repos or refresh from GitHub
    private static func loadOrRefreshCache() throws -> [Repo] {
        // Try to load from cache first
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            do {
                let data = try Data(contentsOf: cacheURL)
                let repos = try JSONDecoder().decode([Repo].self, from: data)
                // Refresh cache in background for next time
                refreshCacheAsync()
                return repos
            } catch {
                // Cache corrupted, refresh now
            }
        }

        // No cache or corrupted, fetch now
        return try refreshCache()
    }

    /// Refresh the repo cache synchronously
    @discardableResult
    private static func refreshCache() throws -> [Repo] {
        let output = try Shell.run("gh", arguments: [
            "repo", "list",
            "--json", "name,nameWithOwner",
            "--limit", "200",
        ])

        guard let data = output.data(using: .utf8) else {
            throw RepoError.cacheError("Invalid output from gh")
        }

        let repos = try JSONDecoder().decode([Repo].self, from: data)

        // Save to cache
        try saveCache(repos)

        return repos
    }

    /// Refresh cache asynchronously (fire and forget)
    private static func refreshCacheAsync() {
        Task.detached(priority: .background) {
            try? refreshCache()
        }
    }

    /// Save repos to cache file
    private static func saveCache(_ repos: [Repo]) throws {
        // Ensure cache directory exists
        let cacheDir = cacheURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        let data = try JSONEncoder().encode(repos)
        try data.write(to: cacheURL)
    }

    enum RepoError: Error, LocalizedError {
        case notFound(String)
        case ambiguous(String, options: String)
        case cacheError(String)

        var errorDescription: String? {
            switch self {
            case let .notFound(name):
                return "Repository '\(name)' not found. Run 'gh repo list' to see available repos."
            case let .ambiguous(name, options):
                return "Multiple repositories match '\(name)': \(options). Use --repo owner/name to specify."
            case let .cacheError(message):
                return "Cache error: \(message)"
            }
        }
    }
}
