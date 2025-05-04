//  Created by Cristian Felipe Patiño Rojas on 2/5/25.

import XCTest

struct Parser {
    func parse(_ request: Request) -> Response {
        Response(statusCode: 400)
    }
}

struct Response {
    let statusCode: Int
}

struct Request {
    let headers: String
}

final class Tests: XCTestCase {
    func test_parser_delivers400ResponseOnEmptyHeaders() {
        let sut = Parser()
        let request = Request(headers: "")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 400)
    }
    
    func test_parser_delivers400OnMalformedHeaders() {
        let sut = Parser()
        let request = Request(headers: "GETHTTP/1.1")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 400)
    }
}
