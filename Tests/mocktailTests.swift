//  Created by Cristian Felipe Patiño Rojas on 2/5/25.

import XCTest

struct Parser {
    let resources: [String]
    func parse(_ request: Request) -> Response {
        guard request.headers.contains("Host") else {
            return Response(statusCode: 400)
        }
        
        guard let resource = request.headers.components(separatedBy: " ").get(at: 1) else {
            return Response(statusCode: 400)
        }
        
        let resourceMainPath = resource.components(separatedBy: "/").dropFirst().first
        
        return Response(statusCode: resources.contains(resourceMainPath ?? "") ? 400 : 404)
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
    
    func test_parser_delivers400OnMissingHostHeader() {
        let sut = makeSUT()
        let request = Request(headers: "GET /recipes HTTP/1.1")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 400)
    }
    
    func test_parser_delivers404OnNonExistentResource() {
        let sut = makeSUT()
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 404)
    }
    
    func test_parser_delivers400OnMalformedId() {
        let sut = makeSUT(resources: ["recipes"])
        let request = Request(headers: "GET /recipes/abc HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 400)
    }
}

// MARK: - Helpers
private extension Tests {
    func makeSUT(resources: [String] = []) -> Parser {
        Parser(resources: resources)
    }
}
