// Created by Cristian Felipe Patiño Rojas on 5/5/25.

import XCTest
@testable import MockTail
import CustomDump

struct Router {
    let request: Request
    func handleRequest() -> Response {
        switch request.route() {
        case .collection where request.method() == .GET: break
        case .resource(_) where request.method() == .GET: break
        case .collection where request.method() == .POST: break
        case .resource(_) where request.method() == .PUT: break
        case .resource(_) where request.method() == .DELETE: break
        case .resource(_) where request.method() == .PATCH: break
        case .nestedSubroute: break
        default: break
        }
        fatalError("")
    }
}

