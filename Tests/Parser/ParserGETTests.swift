// Created by Cristian Felipe Patiño Rojas on 6/5/25.
import MockTail
import CustomDump

// MARK: - GET
extension ParserTests {
    
    func test_GET_delivers200OnRequestOfExistingCollection() {
        let sut = makeSUT(collections: ["recipes": []])
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 200)
    }
    
    
    func test_GET_delivers200OnRequestOFExistingCollectionWithTrailingSlash() {
        let sut = makeSUT(collections: ["recipes": []])
        let request = Request(headers: "GET /recipes/ HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response.statusCode, 200)
    }
    
    func test_GET_delivers200OnRequestOfExistingEmptyCollection() {
        let sut = makeSUT(collections: ["recipes": []])
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response, .OK("[]"))
    }
    
    func test_GET_delivers200OnRequestOfExistingNonEmptyCollection() {
        let item1 = ["id": 1]
        let item2 = ["id": 2]
        let sut = makeSUT(collections: ["recipes": [item1, item2]])
        let request = Request(headers: "GET /recipes HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        
        expectNoDifference(response, .OK(#"[{"id":1},{"id":2}]"#))
    }
    
    func test_GET_delivers200OnRequestOfExistingItem() {
        let item = ["id": "1"]
        let sut = makeSUT(collections: ["recipes": [item]])
        let request = Request(headers: "GET /recipes/1 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        expectNoDifference(response, .OK(#"{"id":"1"}"#))
    }
}
