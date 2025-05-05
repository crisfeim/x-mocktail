// Created by Cristian Felipe Patiño Rojas on 5/5/25.

import Foundation

// Less esoteric version of my beloved `asterisk`
func mutate<T>(_ item: T, withMap map: (inout T) -> Void) -> T {
    item * map
}

// Returns new instance of object with the `rhs` map applied
func *<T>(lhs: T, rhs: (inout T) -> Void) -> T {
    var copy = lhs
    rhs(&copy)
    return copy
}

// Maps `A` to `B`.
// Usage: let intAsString = 3 * String.init
func *<A, B>(lhs: A, rhs: (A) -> B) -> B {
    rhs(lhs)
}
