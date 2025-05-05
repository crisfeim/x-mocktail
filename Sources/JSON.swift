// Created by Cristian Felipe Patiño Rojas on 5/5/25.

public typealias JSON = Any
public typealias JSONItem = [String: JSON]
public typealias JSONArray = [JSONItem]

public extension JSONArray {
    func getItem(with id: Int) -> JSONItem? {
        self.first(where: { $0.getId() == id })
    }
}

public extension JSONItem {
     func getId() -> Int? {
        self["id"] as? Int
    }
}
