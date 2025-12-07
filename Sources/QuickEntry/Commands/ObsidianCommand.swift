import ArgumentParser
import Foundation

struct ObsidianCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ob",
        abstract: "Create a note in Obsidian inbox"
    )

    @Argument(help: "The note content")
    var text: [String]

    mutating func run() throws {
        let config = try Config.load()
        let rawText = text.joined(separator: " ")
        let parsed = InputParser.parse(rawText)

        // Build the content (title + body if multiline)
        var content = parsed.title
        if let body = parsed.body {
            content += "\n\n" + body
        }

        let obsidianURL = try ObsidianService.createInboxNote(
            content: content,
            url: parsed.url,
            config: config
        )

        print(obsidianURL)
    }
}
