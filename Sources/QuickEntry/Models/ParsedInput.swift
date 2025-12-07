import Foundation

/// Represents parsed input with title, optional body, and optional URL
struct ParsedInput: Sendable {
    let title: String
    let body: String?
    let url: URL?

    /// Combined body with URL appended (for destinations that want URL in body)
    var bodyWithURL: String? {
        switch (body, url) {
        case let (body?, url?):
            return body + "\n\n" + url.absoluteString
        case let (nil, url?):
            return url.absoluteString
        case let (body?, nil):
            return body
        case (nil, nil):
            return nil
        }
    }
}
