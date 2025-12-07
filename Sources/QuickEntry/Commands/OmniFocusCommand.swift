import ArgumentParser
import Foundation

struct OmniFocusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "of",
        abstract: "Create a task in OmniFocus inbox"
    )

    @Argument(help: "The task text (first line becomes title, rest becomes note)")
    var text: [String]

    mutating func run() throws {
        let rawText = text.joined(separator: " ")
        let parsed = InputParser.parse(rawText)

        let taskID = try OmniFocusService.createTask(
            title: parsed.title,
            note: parsed.bodyWithURL
        )

        print(OmniFocusService.taskURL(for: taskID))
    }
}
