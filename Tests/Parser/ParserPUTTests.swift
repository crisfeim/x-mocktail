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
            expectNoDifference(response, .OK(#"{"title":"French fries"}"#))
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
            expectNoDifference(response, .OK(#"{"id":1,"title":"New title"}"#))
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
        expectNoDifference(response, .OK(#"{"title":"New title"}"#))
    }
}

