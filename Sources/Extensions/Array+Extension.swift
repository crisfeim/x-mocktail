// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

extension Array {
    func get(at index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}