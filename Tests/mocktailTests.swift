//  Created by Cristian Felipe Patiño Rojas on 2/5/25.

import XCTest
import CustomDump

typealias JSON = Any
typealias JSONItem = [String: JSON]
typealias JSONArray = [JSONItem]

extension JSONArray {
    func getItem(with id: Int) -> JSONItem? {
        self.first(where: { $0.getId() == id })
    }
}

extension JSONItem {
    func getId() -> Int? {
        self["id"] as? Int
    }
}

struct Parser {
    let resources: [String: JSON]
    func parse(_ request: Request) -> Response {
        guard request.headers.contains("Host") else {
            return Response(statusCode: 400)
        }
        
        guard let collectionName = request.collectionName() else {
            return Response(statusCode: 400)
        }
        
        switch request.method() {
        case "GET"   : return handleGET(request, on: collectionName)
        case "DELETE": return handleDELETE(request, on: collectionName)
        case "POST"  : return handlePOST(request, on: collectionName)
        default: return Response(statusCode: 405)
        }
    }
    
    private func handleGET(_ request: Request, on collectionName: String) -> Response {
        
        switch request.type() {
        case .allResources where rawBody(for: collectionName) != nil:
            return Response(
                statusCode: 200,
                rawBody: rawBody(for: collectionName),
                contentLength: rawBody(for: collectionName)?.contentLenght()
            )
        case .singleResource(let id):
            guard let id = Int(id), let item = getItem(withId: id, on: collectionName) else { return Response(statusCode: 404) }
           
            let jsonString =  jsonString(of: item)
            return Response(
                statusCode: 200,
                rawBody: jsonString,
                contentLength: jsonString?.contentLenght()
            )
        default:
            return Response(statusCode: 404)
        }
    }
    
    private func handleDELETE(_ request: Request, on collection: String) -> Response {
        guard
            let idString = request.type().id,
            let id = Int(idString),
            let _ = getItem(withId: id, on: collection)
        else {
            return Response(statusCode: 404)
        }
        return Response(statusCode: 204)
    }
    
    private func handlePOST(_ request: Request, on collection: String) -> Response {
        return Response(statusCode: 415)
    }
    
    private func rawBody(for collectionName: String) -> String? {
        guard let items = resources[collectionName] else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: items) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func getItem(withId id: Int, on collection: String) -> JSONItem? {
        let items = resources[collection] as? JSONArray
        let item = items?.getItem(with: id)
        return item
    }
    
    private func jsonString(of item: JSONItem) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: item) else { return nil }
        return String(data: data, encoding: .utf8)
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
        
        var id: String? {
            if case let .singleResource(id) = self {
                return id
            }
            return nil
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
    
    func test_parser_delivers404OnMalformedId() {
        let sut = makeSUT(resources: ["recipes": []])
        let request1 = Request(headers: "GET /recipes/abc HTTP/1.1\nHost: localhost")
        let response1 = sut.parse(request1)
        expectNoDifference(response1.statusCode, 404)
        
        let request2 = Request(headers: "DELETE /recipes/abc HTTP/1.1\nHost: localhost")
        let response2 = sut.parse(request2)
        expectNoDifference(response2.statusCode, 404)
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
        let request = Request(headers: "Unsupported /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 405)
    }
    
    func test_parser_delivers200OnExistingCollection() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 200)
    }
    
    func test_parser_delivers200OnExistingCollectionWithaTrailingSlash() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET /recipes/ HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 200)
    }
    
    func test_parser_delivers404OnMalformedURL() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET //recipes/ HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 404)
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
        let item1 = ["id": 1]
        let item2 = ["id": 2]
        let sut = makeSUT(resources: ["recipes": [item1, item2]])
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(
            statusCode: 200,
            rawBody: #"[{"id":1},{"id":2}]"#,
            contentLength: 19
        )
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parser_deliversExpectedItemOnExistentItem() {
        let item = ["id": 1]
        let sut = makeSUT(resources: ["recipes": [item]])
        let request = Request(headers: "GET /recipes/1 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(
            statusCode: 200,
            rawBody: #"{"id":1}"#,
            contentLength: 8
        )
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parse_delivers404OnNonExistentItemDeletion() {
        let sut = makeSUT()
        let request = Request(headers: "DELETE /recipes/1 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 404)
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parse_delivers204OnSuccessfulItemDeletion() {
        let item = ["id": 1]
        let sut = makeSUT(resources: ["recipes": [item]])
        let request = Request(headers: "DELETE /recipes/1 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 204)
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parse_delivers415OnMissingContentType() {
        let sut = makeSUT()
        let request = Request(headers: "POST /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 415)
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parse_delivers415OnUnsupportedMediaType() {
        let sut = makeSUT()
        let request = Request(headers: "POST /recipes Content-Type: \(anyNonJSONMediaType()) HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 415)
        
        expectNoDifference(response, expectedResponse)
    }
}

// MARK: - Helpers
private extension Tests {
    func makeSUT(resources: [String: JSON] = [:]) -> Parser {
        Parser(resources: resources)
    }
    
    func anyNonJSONMediaType() -> String {
        "application/freestyle"
    }
}
