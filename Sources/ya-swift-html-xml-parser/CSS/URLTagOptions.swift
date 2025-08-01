/// A set of options that specifies which HTML tags to consider when extracting URLs.
@frozen
public struct URLTagOptions: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let a = URLTagOptions(rawValue: 1 << 0)
    public static let link = URLTagOptions(rawValue: 1 << 1)
    public static let img = URLTagOptions(rawValue: 1 << 2)
    public static let video = URLTagOptions(rawValue: 1 << 3)
    public static let audio = URLTagOptions(rawValue: 1 << 4)
    public static let script = URLTagOptions(rawValue: 1 << 5)
    public static let source = URLTagOptions(rawValue: 1 << 6)
    public static let iframe = URLTagOptions(rawValue: 1 << 7)

    /// A convenience option set for all media-related tags.
    public static let media: URLTagOptions = [.img, .video, .audio, .source]

    /// A convenience option set for all known URL-bearing tags.
    public static let all: URLTagOptions = [
        .a, .link, .img, .video, .audio, .script, .source, .iframe
    ]

    /// The CSS selector string corresponding to the current options.
    var selector: String {
        var tags: [String] = []
        if contains(.a) { tags.append("a") }
        if contains(.link) { tags.append("link") }
        if contains(.img) { tags.append("img") }
        if contains(.video) { tags.append("video") }
        if contains(.audio) { tags.append("audio") }
        if contains(.script) { tags.append("script") }
        if contains(.source) { tags.append("source") }
        if contains(.iframe) { tags.append("iframe") }
        return tags.joined(separator: ", ")
    }
}
