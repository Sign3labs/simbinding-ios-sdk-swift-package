import Foundation

enum Log {
    static func print(_ tag: String, _ message: String) {
        Swift.print("[SIMBinding][\(tag)] \(message)")
    }


    static func pretty(_ data: Data) -> String {
        guard !data.isEmpty else { return "(empty body)" }
        if let object = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
           let text = String(data: pretty, encoding: .utf8) {
            return text
        }
        return String(data: data, encoding: .utf8) ?? "(\(data.count) bytes)"
    }

    static func pretty<T: Encodable>(_ value: T) -> String {
        (try? JSONEncoder().encode(value)).map(pretty) ?? "\(value)"
    }
}
