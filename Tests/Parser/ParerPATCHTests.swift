// Created by Cristian Felipe Patiño Rojas on 6/5/25.

import MockTail
import CustomDump
import XCTest

// MARK: - Patch
extension ParserTests {
    
    func test_parse_delivers404OnPATCHNonExistentResource() {
        let sut = makeSUT(collections: ["recipes": []])
        let request = Request(
            headers: "PATCH /recipes/1 HTTP/1.1\nHost: localhost\nContent-Type: application/json",
            body: #"{"title":"new-title"}"#
        )
        let response = sut.parse(request)
        expectNoDifference(response, .notFound)
    }
    
    func test_parse_delivers400OnPATCHWithValidJSONBodyAndMatchingURLId() {
        let item = ["id": "1"]
        let sut = makeSUT(collections: ["recipes": [item]])
        let request = Request(
            headers: "PATCH /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json",
            body: #"{"id":"1","title":"New title"}"#
        )
        
        let response = sut.parse(request)
        expectNoDifference(response, .badRequest)
    }


    func test_parse_delivers200OnPATCHWithValidJSONBody() throws {
        let original: JSONItem = ["id": "1", "title": "Old title"]
        let sut = makeSUT(collections: ["recipes": [original]])
        let request = Request(
            headers: "PATCH /recipes/1 HTTP/1.1\nHost: localhost\nContent-Type: application/json",
            body: #"{"title":"New title"}"#
        )
        let response = sut.parse(request)
        let expected = Response.OK(#"{"title":"New title","id":"1"}"#)
        
        expectNoDifference(
            try XCTUnwrap(nsDictionary(from: try XCTUnwrap(response.rawBody))),
            try XCTUnwrap(nsDictionary(from: try XCTUnwrap(expected.rawBody)))
        )
    }
}


// MARK: - Helpers
extension ParserTests {
    func makeSUT(collections: [String: JSON] = [:], idGenerator: @escaping () -> String = defaultGenrator, ) -> Parser {
        Parser(collections: collections, idGenerator: idGenerator)
    }
    
    static func defaultGenrator() -> String {
        UUID().uuidString
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
        let sut = makeSUT(collections: ["recipes": [item]])
        
        let request = Request(
            headers: "\(verb) /recipes/1 HTTP/1.1\nHost: localhost\nContent-type: application/json",
            body: ""
        )
        
        let response = sut.parse(request)
        expectNoDifference(response, expectedResponse, "Failed on representation \(emptyJSONRepresentation ?? "null") for verb \(verb)")
    }
}
