// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

enum StatusCode {
    static let notFound = 404
    static let badRequest = 400
    static let unsupportedMethod = 405
    static let missingOrWrongMediaType = 415
}

struct HeadersValidator {
    
    let request: Request
    let collections: [String: JSON]
    
    typealias Result = Int?
    
    var result: Result {
        guard request.headers.contains("Host")  else {
            return StatusCode.badRequest
        }
        
        guard let _ = request.method() else {
            return StatusCode.unsupportedMethod
        }
        
        if request.payloadRequiredRequest() {
            guard let contentType = request.contentType(), contentType == "application/json" else {
                return StatusCode.missingOrWrongMediaType
            }
        }

        return nil
    }
    
    func getItem(withId id: String, on collectionName: String, collections: [String: JSON]) -> JSONItem? {
        let items = collections[collectionName] as? JSONArray
        let item = items?.getItem(with: id)
        return item
    }
}
