// Created by Cristian Felipe Patiño Rojas on 6/5/25.

import MockTail
import XCTest
import CustomDump

// MARK: - PUT
extension ParserTests {
    
    func test_parse_delivers200OnPUTNonExistingResource() {
        XCTExpectFailure {
            let sut = makeSUT(collections: ["recipes": []])
            let request = Request(
                headers: "PUT /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json",
                body: #"{"title":"French fries"}"#
            )
            
            let response = sut.parse(request)
            let expectedResponse = Response(
                statusCode: 200,
                rawBody: #"{"title":"French fries"}"#,
                contentLength: 24
            )
            expectNoDifference(response, expectedResponse)
        }
    }
    
    func test_parse_delivers200OnPUTWithValidJSONBodyAndMatchingURLId() {
        XCTExpectFailure("Reponse paylod should contain item id") {
            let item = ["id": "1"]
            let sut = makeSUT(collections: ["recipes": [item]])
            let request = Request(
                headers: "PUT /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json",
                body: #"{"title":"New title"}"#
            )
            
            let response = sut.parse(request)
            let expectedResponse = Response(
                statusCode: 200,
                rawBody: #"{"id":1,"title":"New title"}"#,
                contentLength: 1
            )
            expectNoDifference(response, expectedResponse)
        }
    }
    
    func test_parse_delivers200OnPUTWithValidJSONBody() {
        let item = ["id": "1"]
        let sut = makeSUT(collections: ["recipes": [item]])
        let request = Request(
            headers: "PUT /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json",
            body: #"{"title":"New title"}"#
        )
        
        let response = sut.parse(request)
        let expectedResponse = Response(
            statusCode: 200,
            rawBody: #"{"title":"New title"}"#,
            contentLength: 21
        )
        expectNoDifference(response, expectedResponse)
    }
}

