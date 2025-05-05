// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

enum JSONUtils {
    static func jsonToString(_ json: JSON) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: json) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func jsonItemToString(_ item: JSONItem) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: item) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func isValidJSON(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }
    
    
    static func jsonItem(from string: String) -> JSONItem? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? JSONItem
    }
    
    static func isValidNonEmptyJSON(_ body: String?) -> Bool {
        guard let body = body, JSONUtils.isValidJSON(body) else { return false }
        return body.removingSpaces().removingBreaklines() != "{}"
    }
}