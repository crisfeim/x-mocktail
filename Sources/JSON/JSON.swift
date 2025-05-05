// Created by Cristian Felipe Patiño Rojas on 5/5/25.

public typealias JSON = Any
public typealias JSONItem = [String: JSON]
public typealias JSONArray = [JSONItem]

public extension JSONArray {
    func getItem(with id: String) -> JSONItem? {
        self.first(where: { $0.getId() == id })
    }
}

public extension JSONItem {
     func getId() -> String? {
        self["id"] as? String
    }
    
    func applyPatch(_ patch: JSONItem) -> JSONItem {
        mutate(self, withMap: {
            for (key, value) in patch { $0[key] = value }
        })
    }
}
