//  Created by Cristian Felipe Patiño Rojas on 2/5/25.

import XCTest

struct Parser {
    let resources: [String]
    func parse(_ request: Request) -> Response {
        guard let _ = request.headers.components(separatedBy: " ").get(at: 2) else {
            return Response(statusCode: 400)
        }
        
        return Response(statusCode: 404)
    }
}

fileprivate extension Array {
    func get(at index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
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
        let sut = makeSUT()
        let request = Request(headers: "")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 400)
    }
    
    func test_parser_delivers400OnMalformedHeaders() {
        let sut = makeSUT()
        let request = Request(headers: "GETHTTP/1.1")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 400)
    }
    
    func test_parser_delivers404OnNonExistentResource() {
        let sut = makeSUT()
        let request = Request(headers: "GET /recipes HTTP/1.1")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 404)
    }
}

// MARK: - Helpers
private extension Tests {
    func makeSUT(resources: [String] = []) -> Parser {
        Parser(resources: resources)
    }
}
