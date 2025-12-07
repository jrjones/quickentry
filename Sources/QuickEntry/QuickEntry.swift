import ArgumentParser
import Foundation

@main
struct QuickEntry: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "qe",
        abstract: "Quick entry to various destinations",
        discussion: """
            Capture thoughts to the right destination with minimal friction.

            Examples:
              qe gh fix the bug           # GitHub issue (in a repo)
              qe gh neodeck fix bug       # GitHub issue (outside repo)
              qe of call dentist          # OmniFocus inbox
              qe ob interesting idea      # Obsidian inbox
              qe random thought           # Fallback to OmniFocus
            """,
        version: "1.0.0",
        subcommands: [GitHubCommand.self, OmniFocusCommand.self, ObsidianCommand.self, ObsidianCleanCommand.self],
        defaultSubcommand: OmniFocusCommand.self
    )
}
