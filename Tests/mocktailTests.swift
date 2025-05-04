//  Created by Cristian Felipe Patiño Rojas on 2/5/25.

import XCTest

struct Parser {
    let resources: [String: [Int]]
    func parse(_ request: Request) -> Response {
        guard request.headers.contains("Host") else {
            return Response(statusCode: 400)
        }
        
        guard request.method() == "GET" else {
            return Response(statusCode: 405)
        }
        
        guard request.urlComponents().count == 2 else {
            return Response(statusCode: 404)
        }
        
        guard let collectionName = request.collectionName() else {
            return Response(statusCode: 400)
        }
        
        guard let id = request.id() else {
            return Response(statusCode: collectionExists(collectionName) ? 400 : 404)
        }
        
        guard let id = Int(id) else { return Response(statusCode: 400) }
        let items = resources[collectionName] ?? []
        
        return Response(statusCode: items.contains(id) ? 400 : 404)
    }
    
    private func collectionExists(_ collectionName: String) -> Bool {
        resources.map(\.key).contains(collectionName)
    }
}

private extension Request {
    func url() -> String? {
        headers.components(separatedBy: " ").get(at: 1)
    }
    
    func urlComponents() -> [String] {
       Array(url()?.components(separatedBy: "/").dropFirst() ?? [])
    }
    
    func id() -> String? {
        urlComponents().get(at: 1)
    }
    
    func collectionName() -> String? {
        urlComponents().first
    }
    
    func method() -> String? {
        headers.components(separatedBy: "\n").first?.components(separatedBy: " ").first
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
    
    func test_parser_delivers404OnNonExistentCollection() {
        let sut = makeSUT()
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 404)
    }
    
    func test_parser_delivers400OnMalformedId() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET /recipes/abc HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 400)
    }
    
    func test_parser_delivers404OnNonExistentResource() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET /recipes/2 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 404)
    }
    
    func test_parser_delivers404OnUnknownSubroute() {
        let sut = makeSUT(resources: ["recipes": [1]])
        let request = Request(headers: "GET /recipes/1/helloworld HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 404)
    }
    
    func test_parser_delivers405OnUnsupportedMethod() {
        let sut = makeSUT()
        let request = Request(headers: "POST /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        XCTAssertEqual(response.statusCode, 405)
    }
}

// MARK: - Helpers
private extension Tests {
    func makeSUT(resources: [String: [Int]] = [:]) -> Parser {
        Parser(resources: resources)
    }
}
