//  Created by Cristian Felipe Patiño Rojas on 2/5/25.

import XCTest
import CustomDump

struct Parser {
    let resources: [String: [Int]]
    func parse(_ request: Request) -> Response {
        guard request.headers.contains("Host") else {
            return Response(statusCode: 400)
        }
        
        guard request.method() == "GET" else {
            return Response(statusCode: 405)
        }
        
        guard let collectionName = request.collectionName() else {
            return Response(statusCode: 400)
        }
        
        switch request.type() {
        case .allResources where rawBody(for: collectionName) != nil:
            return Response(
                statusCode: 200,
                rawBody: rawBody(for: collectionName),
                contentLength: rawBody(for: collectionName)?.contentLenght()
            )
        case .singleResource(let id):
            guard let id = Int(id) else { return Response(statusCode: 400) }
            let item = resources[collectionName]?.first(where: { $0 == id })
            return Response(
                statusCode: item != nil ? 200 : 404,
                rawBody: item?.description,
                contentLength: item?.description.contentLenght()
            )
        default:
            return Response(statusCode: 404)
        }
    }
    
    private func rawBody(for collectionName: String) -> String? {
        resources[collectionName]?.description.removingSpaces()
    }
}

private extension Response {
    init(
        statusCode: Int,
        rawBody: String? = nil,
        contentLength: Int? = nil
    ) {
        let date = Self.dateFormatter.string(from: Date())
        self.statusCode = statusCode
        headers = [
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, HEAD, PUT, PATCH, POST, DELETE",
            "Access-Control-Allow-Headers": "content-type",
            "Content-Type": "application/json",
            "Date": date,
            "Connection": "close",
            "Content-Length": contentLength?.description
        ].compactMapValues { $0 }
        
        self.rawBody = rawBody
    }
    
    static let dateFormatter = DateFormatter() * { df in
        df.dateFormat = "EEE',' dd MMM yyyy HH:mm:ss zzz"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
    }
}

func *<T>(lhs: T, rhs: (inout T) -> Void) -> T {
    var copy = lhs
    rhs(&copy)
    return copy
}

private extension Request {
    func normalizedURL() -> String? {
        requestHeaders().first?
            .components(separatedBy: " ")
            .get(at: 1)?
            .trimInitialAndLastSlashes()
    }
    
    func requestHeaders() -> [String] {
        headers.components(separatedBy: "\n")
    }
    
    func urlComponents() -> [String] {
        Array(normalizedURL()?.components(separatedBy: "/") ?? [])
    }
    
    func id() -> String? {
        urlComponents().get(at: 1)
    }
    
    func collectionName() -> String? {
        urlComponents().first
    }
    
    func method() -> String? {
        requestHeaders().first?.components(separatedBy: " ").first
    }
    
    func allItems() -> Bool {
        urlComponents().count == 1
    }
    
    enum RequestType {
        case allResources
        case singleResource(id: String)
        case subroute
        
        init(_ urlComponents: [String]) {
            switch urlComponents.count {
            case 1: self = .allResources
            case 2: self = .singleResource(id: urlComponents[1])
            default: self = .subroute
            }
        }
    }
    
    func type() -> RequestType {
        RequestType(urlComponents())
    }
}

private extension String {
    func contentLenght() -> Int {
        data(using: .utf8)?.count ?? count
    }
    
    func removingSpaces() -> String {
        self.replacingOccurrences(of: " ", with: "")
    }
    
    func trimInitialAndLastSlashes() -> String {
        var copy = self
        if copy.first == "/" {
            copy.removeFirst()
        }
        if copy.last == "/" {
            copy.removeLast()
        }
        
        return copy
    }
}

fileprivate extension Array {
    func get(at index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
struct Response: Equatable {
    let statusCode: Int
    let headers: [String: String]
    let rawBody: String?
}

struct Request {
    let headers: String
}

final class Tests: XCTestCase {
    func test_parser_delivers400ResponseOnEmptyHeaders() {
        let sut = makeSUT()
        let request = Request(headers: "")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 400)
    }
    
    func test_parser_delivers400OnMalformedHeaders() {
        let sut = makeSUT()
        let request = Request(headers: "GETHTTP/1.1")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 400)
    }
    
    func test_parser_delivers400OnMissingHostHeader() {
        let sut = makeSUT()
        let request = Request(headers: "GET /recipes HTTP/1.1")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 400)
    }
    
    func test_parser_delivers404OnNonExistentCollection() {
        let sut = makeSUT()
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 404)
    }
    
    func test_parser_delivers400OnMalformedId() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET /recipes/abc HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 400)
    }
    
    func test_parser_delivers404OnNonExistentResource() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET /recipes/2 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 404)
    }
    
    func test_parser_delivers404OnUnknownSubroute() {
        let sut = makeSUT(resources: ["recipes": [1]])
        let request = Request(headers: "GET /recipes/1/helloworld HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 404)
    }
    
    func test_parser_delivers405OnUnsupportedMethod() {
        let sut = makeSUT()
        let request = Request(headers: "POST /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 405)
    }
    
    func test_parser_delivers200OnExistingCollection() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 200)
    }
    
    func test_parser_delivers200OnExistingResource() {
        let sut = makeSUT(resources: ["recipes": [1]])
        let request = Request(headers: "GET /recipes/1 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 200)
    }
    
    func test_parser_delivers200OnExistingCollectionWithaTrailingSlash() {
        let sut = makeSUT(resources: ["recipes": [1, 2]])
        let request = Request(headers: "GET /recipes/ HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 200)
    }
    
    func test_parser_delivers400OnMalformedURL() {
        let sut = makeSUT(resources: ["recipes": [1, 2]])
        let request = Request(headers: "GET //recipes/ HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 400)
    }
    
    func test_parser_deliversEmptyJSONArrayOnEmptyCollection() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(
            statusCode: 200,
            rawBody: "[]",
            contentLength: 2
        )
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parser_deliversExpectedArrayOnNonEmptyCollection() {
        let sut = makeSUT(resources: ["recipes": [1,2]])
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(
            statusCode: 200,
            rawBody: "[1,2]",
            contentLength: "[1,2]".count
        )
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parser_deliversExpectedItemOnExistentItem() {
        let sut = makeSUT(resources: ["recipes": [1]])
        let request = Request(headers: "GET /recipes/1 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(
            statusCode: 200,
            rawBody: "1",
            contentLength: 1
        )
        
        expectNoDifference(response, expectedResponse)
    }
}

// MARK: - Helpers
private extension Tests {
    func makeSUT(resources: [String: [Int]] = [:]) -> Parser {
        Parser(resources: resources)
    }
}
