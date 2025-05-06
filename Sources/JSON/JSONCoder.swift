// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

enum JSONCoder {
    static func encode(_ json: JSON) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: json) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func encode(_ json: JSONItem) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: json) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func decode<T>(_ data: String) -> T? {
        guard let data = data.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? T
    }
}

enum JSONValidator {
    static func isValidJSON(_ data: String) -> Bool {
        guard let data = data.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }
    
    static func isEmptyJSON(_ data: String) -> Bool {
        data.isEmpty || data.removingAllWhiteSpaces() == "{}"
    }
}

fileprivate extension String {
    func removingAllWhiteSpaces() -> String {
        self.removingSpaces().removingBreaklines()
    }
}
