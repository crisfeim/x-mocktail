//  Created by Cristian Felipe Patiño Rojas on 2/5/25.

import XCTest
import CustomDump
import MockTail


final class ParserTests: XCTestCase {
    func test_parser_delivers405OnUnsupportedMethod() {
        let sut = makeSUT()
        let request = Request(headers: "Unsupported /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response, .unsopportedMethod)
    }
}

// MARK: - Common
extension ParserTests {
    func test_parser_delivers400ResponseOnEmptyHeaders() {
        let sut = makeSUT()
        let request = Request(headers: "")
        let response = sut.parse(request)
        expectNoDifference(response, .badRequest)
    }
    
    func test_parser_delivers400OnMalformedHeaders() {
        let sut = makeSUT()
        let request = Request(headers: "GETHTTP/1.1")
        let response = sut.parse(request)
        expectNoDifference(response, .badRequest)
    }
    
    func test_parser_delivers400OnMissingHostHeader() {
        let sut = makeSUT()
        let request = Request(headers: "GET /recipes HTTP/1.1")
        let response = sut.parse(request)
        expectNoDifference(response, .badRequest)
    }
    
    func test_parser_delivers404OnNonExistentCollection() {
        let sut = makeSUT()
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response, .notFound)
    }
    
    func test_parser_delivers404OnDELETEMalformedId() {
        let sut = makeSUT(collections: ["recipes": []])
        let request = Request(headers: "DELETE /recipes/abc HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response, .notFound)
    }
    
    func test_parser_delivers404OnNonExistentResource() {
        let sut = makeSUT(collections: ["recipes": []])
        let request = Request(headers: "GET /recipes/2 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response, .notFound)
    }
    
    func test_parser_delivers400OnUnknownSubroute() {
        let sut = makeSUT(collections: ["recipes": [1]])
        let request = Request(headers: "GET /recipes/1/helloworld HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response, .badRequest)
    }

    func test_parse_delivers415OnPayloadRequiredRequestsMissingContentTypeHeader() {
        let sut = makeSUT(collections: ["recipes": []])
        
        ["POST", "PATCH", "PUT"].forEach { verb in
            let request = Request(headers: "\(verb) /recipes HTTP/1.1\nHost: localhost")
            let response = sut.parse(request)
            
            expectNoDifference(response, .unsupportedMediaType, "Failed on \(verb)")
        }
    }
    
    func test_parse_delivers415OnPayloadRequiredRequestsUnsupportedMediaType() {
        let sut = makeSUT(collections: ["recipes": []])
        
        ["POST", "PATCH", "PUT"].forEach { verb in
            let request = Request(headers: "\(verb) /recipes\nContent-Type: \(anyNonJSONMediaType()) HTTP/1.1\nHost: localhost")
            let response = sut.parse(request)
            
            expectNoDifference(response, .unsupportedMediaType, "Failed on \(verb)")
        }
    }
 
    func test_parse_delivers400OnPayloadAndIDRequiredRequestsWithInvalidJSONBody() {
        let sut = makeSUT(collections: ["recipes": [["id": "1"]]])
        
        ["PATCH", "PUT"].forEach { verb in
            let request = Request(
                headers: "\(verb) /recipes/1\nContent-Type: application/json\nHost: localhost",
                body: "invalid json"
            )
            let response = sut.parse(request)
            
            expectNoDifference(response, .badRequest, "Failed on \(verb)")
        }
    }
    
    func test_parse_delivers400OnPayloadRequiredRequestsWithEmptyJSON() {
        expect(.badRequest, on: "{}", for: "PATCH")
        expect(.badRequest, on: "{ }", for: "PATCH")
        expect(.badRequest, on: "{\n}", for: "PATCH")
        expect(.badRequest, on: nil, for: "PATCH")
        expect(.badRequest, on: "{}", for: "PUT")
        expect(.badRequest, on: "{ }", for: "PUT")
        expect(.badRequest, on: "{\n}", for: "PUT")
        expect(.badRequest, on: nil, for: "PUT")
    }
    
    func test_parse_delivers400OnPayloadAndIDRequiredRequestsWithJSONBodyWithDifferentItemId() {
        let item1: JSONItem = ["id": "1", "title": "KFC Chicken"]
        let item2: JSONItem = ["id": "2", "title": "Sushi rolls"]
        let sut = makeSUT(collections: ["recipes": [item1, item2]])
        
        ["PATCH", "POST"].forEach { verb in
            let request = Request(
                headers: "\(verb) /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json",
                body: #"{"id":"2","title":"Fried chicken"}"#
            )
            
            let response = sut.parse(request)
            expectNoDifference(response, .badRequest)
        }
    }
    
    func test_parse_delivers400OnIdRequiredRequestWithNoIdOnRequestURL() {
        let sut = makeSUT(collections: ["recipes": [:]])
        ["DELETE", "PATCH", "PUT"].forEach { verb in
            let request = Request(headers: "\(verb) /recipes HTTP/1.1\nHost: localhost\nContent-Type: application/json", body: "any payload")
            let response = sut.parse(request)
            expectNoDifference(response, .badRequest, "Expect failed for \(verb)")
        }
    }
    
    func test_parse_delivers400OnIDRequiredRequestsWhenIDPresentWithinPayloadBody()  {
        let sut = makeSUT(collections: ["recipes": ["id":"1"]])
        ["PATCH", "PUT"].forEach { verb in
            let request = Request(
                headers: "\(verb) /recipes HTTP/1.1\nHost: localhost\nContent-Type: application/json",
                body: #"{"id": "2"}"#
            )
            let response = sut.parse(request)
            expectNoDifference(response, .badRequest, "Expect failed for \(verb)")
        }
    }
}


