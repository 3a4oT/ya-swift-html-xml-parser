/// An enum to represent the size of a data chunk in various units.
@frozen
public enum ChunkSize: Sendable {
    /// Size in bytes.
    case bytes(Int)

    /// Size in kilobytes.
    case kilobytes(Int)

    /// Size in megabytes.
    case megabytes(Int)

    /// The computed value of the chunk size in bytes.
    var valueInBytes: Int {
        switch self {
        case let .bytes(value):
            return value
        case let .kilobytes(value):
            // 1 KB = 1024 bytes
            return value * 1024
        case let .megabytes(value):
            // 1 MB = 1024 * 1024 bytes
            return value * 1024 * 1024
        }
    }
}
