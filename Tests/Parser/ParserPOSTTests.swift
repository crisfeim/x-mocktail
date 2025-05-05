// Created by Cristian Felipe Patiño Rojas on 6/5/25.

import MockTail
import CustomDump
import XCTest

// MARK: - POST
extension ParserTests {
    
    func test_parse_delivers400OnPOSTWithInvalidJSONBody() {
        let sut = makeSUT(collections: ["recipes": [["id": 1]]])
     
        let request = Request(
            headers: "POST /recipes\nContent-Type: application/json\nHost: localhost",
            body: "invalid json"
        )
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 400)
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parse_delivers400OnPostWithJSONBodyWithItemId() {
        let sut = makeSUT(collections: ["recipes": []])
        let request = Request(
            headers: "POST /recipes HTTP/1.1\nHost: localhost\nContent-type: application/json",
            body: #"{"id": 1,"title":"Fried chicken"}"#
        )
        
        let response = sut.parse(request)
        let expectedResponse = Response(statusCode: 400)
        
        expectNoDifference(response, expectedResponse)
    }
    
    func test_parse_delivers201OnPOSTWithValidJSONBody() throws {
        let newId = UUID().uuidString
        let sut = makeSUT(collections: ["recipes": []], idGenerator: {newId})
        let request = Request(
            headers: "POST /recipes HTTP/1.1\nHost: localhost\nContent-type: application/json",
            body: #"{"title":"Fried chicken"}"#
        )
        let response = sut.parse(request)
        let expectedResponse = Response(
            statusCode: 201,
            rawBody: "{\"id\":\"\(newId)\",\"title\":\"Fried chicken\"}",
            contentLength: 69
        )
        
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
   
