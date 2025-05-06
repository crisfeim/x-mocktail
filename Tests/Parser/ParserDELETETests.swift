// Created by Cristian Felipe Patiño Rojas on 6/5/25.

import MockTail
import CustomDump
import XCTest

// MARK: - DELETE
extension ParserTests {
    func test_DELETE_delivers404OnDeleteRequestToAnUnexistentItem() {
        let sut = makeSUT()
        let request = Request(headers: "DELETE /recipes/1 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        
        expectNoDifference(response, .notFound)
    }
    
    func test_DELETE_delivers204OnSuccessfulItemDeletion() {
        let item = ["id": "1"]
        let sut = makeSUT(collections: ["recipes": [item]])
        let request = Request(headers: "DELETE /recipes/1 HTTP/1.1\nHost: localhost")
        let response = sut.parse(request)
        
        expectNoDifference(response, .empty)
    }
}
