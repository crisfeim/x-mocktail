//  Created by Cristian Felipe Patiño Rojas on 2/5/25.

import XCTest
import CustomDump
import MockTail


final class Tests: XCTestCase {
    func test_parser_delivers405OnUnsupportedMethod() {
        let sut = makeSUT()
        let request = Request(headers: "Unsupported /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 405)
    }
}

// MARK: - Common
extension Tests {
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

    
    func test_parser_delivers404OnMalformedURL() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET //recipes/ HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 404)
    }
    
    func test_parse_delivers415OnPayloadRequiredVerbsMissingContentTypeHeader() {
        let sut = makeSUT(resources: ["recipes": []])
        
        ["POST", "PATCH", "PUT"].forEach { verb in
            let request = Request(headers: "\(verb) /recipes HTTP/1.1\nHost: localhost")
            let response = sut.parse(request)
            let expectedResponse = Response(statusCode: 415)
            
            
            expectNoDifference(response, expectedResponse, "Failed on \(verb)")
        }
    }
    
    func test_parse_delivers415OnPayloadRequiredVerbsUnsupportedMediaType() {
        let sut = makeSUT(resources: ["recipes": []])
        
        ["POST", "PATCH", "PUT"].forEach { verb in
            let request = Request(headers: "\(verb) /recipes\nContent-Type: \(anyNonJSONMediaType()) HTTP/1.1\nHost: localhost")
            let response = sut.parse(request)
            let expectedResponse = Response(statusCode: 415)
            
            expectNoDifference(response, expectedResponse, "Failed on \(verb)")
        }
    }
 
    func test_parse_delivers400OnPayloadAndIdRequiredVerbsWithInvalidJSONBody() {
        let sut = makeSUT(resources: ["recipes": [["id": "1"]]])
        
        ["PATCH", "PUT"].forEach { verb in
            let request = Request(
                headers: "\(verb) /recipes/1\nContent-Type: application/json\nHost: localhost",
                body: "invalid json"
            )
            let response = sut.parse(request)
            let expectedResponse = Response(statusCode: 400)
            
            expectNoDifference(response, expectedResponse, "Failed on \(verb)")
        }
    }
    
    func test_parse_delivers400OnPayloadRequiredVerbsWithEmptyJSON() {
        let expectedResponse = Response(statusCode: 400)
        expect(expectedResponse, on: "{}", for: "PATCH")
        expect(expectedResponse, on: "{ }", for: "PATCH")
        expect(expectedResponse, on: "{\n}", for: "PATCH")
        expect(expectedResponse, on: nil, for: "PATCH")
        expect(expectedResponse, on: "{}", for: "PUT")
        expect(expectedResponse, on: "{ }", for: "PUT")
        expect(expectedResponse, on: "{\n}", for: "PUT")
        expect(expectedResponse, on: nil, for: "PUT")
    }
    
    func test_parse_delivers404OnPayloadRequiredVerbsNonExistingCollection() {
        let sut = makeSUT()
        ["POST", "PATCH", "PUT"].forEach { verb in
            let request = Request(headers: "\(verb) /nonExistingCollection HTTP/1.1\nHost: localhost", body: "any body")
            
            let response = sut.parse(request)
            let expectedResponse = Response(statusCode: 404)
            expectNoDifference(response, expectedResponse)
        }
    }
    
    func test_parse_delivers400OnPayloadAndIdRequiredVerbsWithJSONBodyWithDifferentItemId() {
        let item1: JSONItem = ["id": "1", "title": "KFC Chicken"]
        let item2: JSONItem = ["id": "2", "title": "Sushi rolls"]
        let sut = makeSUT(resources: ["recipes": [item1, item2]])
        
        ["PATCH", "POST"].forEach { verb in
            let request = Request(
                headers: "\(verb) /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json",
                body: #"{"id":"2","title":"Fried chicken"}"#
            )
            
            let response = sut.parse(request)
            let expectedResponse = Response(statusCode: 400)
            
            expectNoDifference(response, expectedResponse)
        }
    }
}

// MARK: - GET
extension Tests {
    
    func test_parser_delivers200GOnGETExistingCollection() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 200)
    }
    
    
    func test_parser_delivers200OnGETExistingCollectionWithaTrailingSlash() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "GET /recipes/ HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 200)
    }
    
    func test_parser_deliversEmptyJSONArrayOnGETEmptyCollection() {
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
    
    func test_parser_deliversExpectedArrayOnNonGETEmptyCollection() {
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
    
    func test_parser_deliversExpectedItemOnGETExistentItem() {
        let item = ["id": "1"]
        let sut = makeSUT(resources: ["recipes": [item]])
        let request = Request(headers: "GET /recipes/1 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(
            statusCode: 200,
            rawBody: #"{"id":"1"}"#,
            contentLength: 10
        )
        
        expectNoDifference(response, expectedResponse)
    }
    
}

// MARK: - DELETE
extension Tests {
    func test_parse_delivers404OnNonExistentItemDeletion() {
        let sut = makeSUT()
        let request = Request(headers: "DELETE /recipes/1 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 404)
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parse_delivers204OnSuccessfulItemDeletion() {
        let item = ["id": "1"]
        let sut = makeSUT(resources: ["recipes": [item]])
        let request = Request(headers: "DELETE /recipes/1 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 204)
        
        expectNoDifference(response, expectedResponse)
    }
}

// MARK: - POST
extension Tests {
    
    func test_parse_delivers400OnPOSTWithInvalidJSONBody() {
        let sut = makeSUT(resources: ["recipes": [["id": 1]]])
     
        let request = Request(
            headers: "POST /recipes\nContent-Type: application/json\nHost: localhost",
            body: "invalid json"
        )
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 400)
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parse_delivers400OnPostWithJSONBodyWithItemId() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(
            headers: "POST /recipes HTTP/1.1\nHost: localhost\nContent-type: application/json",
            body: #"{"id": 1,"title":"Fried chicken"}"#
        )
        
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 400)
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parse_delivers201OnPOSTWithValidJSONBody() throws {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(
            headers: "POST /recipes HTTP/1.1\nHost: localhost\nContent-type: application/json",
            body: #"{"title":"Fried chicken"}"#
        )
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 201, rawBody: #"{"id": 1,"title":"Fried chicken"}"#)
        
        expectNoDifference(response.statusCode, expectedResponse.statusCode)
        expectNoDifference(response.headers, expectedResponse.headers)
        
        let responseBody = try XCTUnwrap(response.rawBody)
        let expectedBody = try XCTUnwrap(expectedResponse.rawBody)
        
        expectNoDifference(
            try XCTUnwrap(nsDictionary(from: responseBody)),
            try XCTUnwrap(nsDictionary(from: expectedBody))
        )
    }
}
   
// MARK: - PUT
extension Tests {

    func test_parse_delivers200OnPUTNonExistingResource() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "PUT /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json")
        
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 200)
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parse_delivers200OnPUTWithValidJSONBodyAndMatchingURLId() {
        let item = ["id": 1]
        let sut = makeSUT(resources: ["recipes": [item]])
        let request = Request(
            headers: "PUT /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json",
            body: #"{"id":1,"title":"New title"}"#
        )
        
        let response = sut.parse(request)
        let expectedResponse = Response(
            statusCode: 200,
            rawBody: #"{"id":1,"title":"New title"}"#
        )
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parse_delivers200OnPUTWithValidJSONBody() {
        let item = ["id": 1]
        let sut = makeSUT(resources: ["recipes": [item]])
        let request = Request(
            headers: "PUT /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json",
            body: #"{"title":"New title"}"#
        )
        
        let response = sut.parse(request)
        let expectedResponse = Response(
            statusCode: 200,
            rawBody: #"{"title":"New title"}"#
        )
        expectNoDifference(response, expectedResponse)
    }
}

// MARK: - Patch
extension Tests {
    
    func test_parse_delivers404OnPATCHNonExistentResource() {
        let sut = makeSUT(resources: ["recipes": []])
        let request = Request(headers: "PATCH /recipes/1 HTTP/1.1\nHost: localhost\nContent-Type: application/json")
        let response = sut.parse(request)
        expectNoDifference(response, Response(statusCode: 404))
    }
    
    func test_parse_delivers200OnPATCHWithValidJSONBodyAndMatchingURLId() {
        let item = ["id": "1"]
        let sut = makeSUT(resources: ["recipes": [item]])
        let request = Request(
            headers: "PATCH /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json",
            body: #"{"id":"1","title":"New title"}"#
        )
        
        let response = sut.parse(request)
        let expectedResponse = Response(
            statusCode: 200,
            rawBody: #"{"id":"1","title":"New title"}"#
        )
        expectNoDifference(response, expectedResponse)
    }


    func test_parse_delivers200OnPATCHWithValidJSONBody() throws {
        let original: JSONItem = ["id": "1", "title": "Old title"]
        let sut = makeSUT(resources: ["recipes": [original]])
        let request = Request(
            headers: "PATCH /recipes/1 HTTP/1.1\nHost: localhost\nContent-Type: application/json",
            body: #"{"title":"New title"}"#
        )
        let response = sut.parse(request)
        let expected = Response(
            statusCode: 200,
            rawBody: #"{"title":"New title","id":"1"}"#,
            contentLength: 28
        )
        
        expectNoDifference(
            try XCTUnwrap(nsDictionary(from: try XCTUnwrap(response.rawBody))),
            try XCTUnwrap(nsDictionary(from: try XCTUnwrap(expected.rawBody)))
        )
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
    
    func nsDictionary(from jsonString: String) -> NSDictionary? {
        guard
            let responseJSON = try? JSONSerialization.jsonObject(with: Data(jsonString.utf8)),
            let responseDict = responseJSON as? NSDictionary
        else {
            return nil
        }
        return responseDict
    }
    
    func expect(
        _ expectedResponse: Response,
        on emptyJSONRepresentation: String?,
        for verb: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let item = ["id": "1"]
        let sut = makeSUT(resources: ["recipes": [item]])
        
        let request = Request(
            headers: "\(verb) /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json",
            body: nil
        )
        
        let response = sut.parse(request)
        expectNoDifference(response, expectedResponse, "Failed on representation \(emptyJSONRepresentation ?? "null") for verb \(verb)")
    }
}
