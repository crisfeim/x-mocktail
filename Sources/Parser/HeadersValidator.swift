// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

struct HeadersValidator {
    
    enum ValidationError: Int, Swift.Error {
        case notFound = 404
        case badRequest = 400
        case unsupportedMethod = 405
        case missingOrWrongMediaType = 415
    }
    
    let request: Request
    let collections: [String: JSON]
    
    typealias Result = Swift.Result<Void, ValidationError>
    
    var result: Result {
        guard request.headers.contains("Host"), let collectionName = request.collectionName()  else {
            return .failure(.badRequest)
        }
        
        guard let _ = request.method() else {
            return .failure(.unsupportedMethod)
        }
        
        if request.payloadRequiredRequest() {
            guard let contentType = request.contentType(), contentType == "application/json" else {
                return .failure(.missingOrWrongMediaType)
            }
        }
        
        if [Request.HTTPVerb.DELETE, .PATCH].contains(request.method()) {
            
            guard let id = request.route().id else {
                return .failure(.badRequest)
            }
               guard let _ = getItem(withId: id, on: collectionName, collections: collections) else {
             return .failure(.notFound)
         }
        }
        
        return .success(())
    }
    
    func getItem(withId id: String, on collectionName: String, collections: [String: JSON]) -> JSONItem? {
        let items = collections[collectionName] as? JSONArray
        let item = items?.getItem(with: id)
        return item
    }
}