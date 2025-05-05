// Created by Cristian Felipe Patiño Rojas on 5/5/25.

import Foundation

func *<T>(lhs: T, rhs: (inout T) -> Void) -> T {
    var copy = lhs
    rhs(&copy)
    return copy
}
