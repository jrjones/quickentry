import ArgumentParser
import Foundation

struct ObsidianCleanCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "oclean",
        abstract: "Move QuickEntry inbox notes to daily note"
    )

    @Flag(name: .shortAndLong, help: "Show what would be done without making changes")
    var dryRun: Bool = false

    mutating func run() throws {
        let config = try Config.load()
        let result = try ObsidianService.cleanInbox(config: config, dryRun: dryRun)

        if result.movedCount == 0 {
            print("No QuickEntry notes found in inbox.")
        } else if dryRun {
            print("Would move \(result.movedCount) note(s) to daily note:")
            for file in result.files {
                print("  - \(file)")
            }
        } else {
            print("Moved \(result.movedCount) note(s) to \(result.dailyNotePath)")
        }
    }
}
