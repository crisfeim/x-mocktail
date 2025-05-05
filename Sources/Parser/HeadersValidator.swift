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
        
        guard request.hasWrongOrMissingContentType() && request.isPayloadRequired() else {
                return nil
        }

        return StatusCode.missingOrWrongMediaType
    }
}
