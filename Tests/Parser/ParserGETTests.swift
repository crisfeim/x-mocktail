// Created by Cristian Felipe Patiño Rojas on 6/5/25.
import MockTail
import CustomDump

// MARK: - GET
extension ParserTests {
    
    func test_parser_delivers200GOnGETExistingCollection() {
        let sut = makeSUT(collections: ["recipes": []])
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 200)
    }
    
    
    func test_parser_delivers200OnGETExistingCollectionWithaTrailingSlash() {
        let sut = makeSUT(collections: ["recipes": []])
        let request = Request(headers: "GET /recipes/ HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 200)
    }
    
    func test_parser_deliversEmptyJSONArrayOnGETEmptyCollection() {
        let sut = makeSUT(collections: ["recipes": []])
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
        let sut = makeSUT(collections: ["recipes": [item1, item2]])
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
        let sut = makeSUT(collections: ["recipes": [item]])
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
