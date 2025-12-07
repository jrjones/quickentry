import ArgumentParser
import Foundation

struct GitHubCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gh",
        abstract: "Create a GitHub issue"
    )

    @Option(name: .long, help: "Override the repository (owner/repo or just repo name)")
    var repo: String?

    @Argument(help: "The issue text (first line becomes title, rest becomes body)")
    var text: [String]

    mutating func run() throws {
        let config = try Config.load()

        // Determine the target repo
        let targetRepo: String
        if let explicitRepo = repo {
            // Explicit --repo flag takes precedence
            targetRepo = try GitHubService.resolveRepo(explicitRepo, config: config)
        } else if Shell.isInGitRepo(),
                  let remoteURL = Shell.getGitRemoteURL(),
                  let (owner, repoName) = Shell.parseGitHubRepo(from: remoteURL)
        {
            // In a git repo with GitHub remote - use that
            targetRepo = "\(owner)/\(repoName)"
        } else if !text.isEmpty {
            // Not in a git repo - first argument must be repo name
            let repoArg = text[0]
            targetRepo = try GitHubService.resolveRepo(repoArg, config: config)
            // Remove repo from text
            text = Array(text.dropFirst())
        } else {
            throw ValidationError("No repository specified. Either run from within a git repo or provide a repo name.")
        }

        guard !text.isEmpty else {
            throw ValidationError("No issue text provided.")
        }

        let rawText = text.joined(separator: " ")
        let parsed = InputParser.parse(rawText)

        let issueURL = try GitHubService.createIssue(
            repo: targetRepo,
            title: parsed.title,
            body: parsed.bodyWithURL
        )

        print(issueURL)
    }
}
