// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

struct HeadersValidator {
    
    let request: Request
    let collections: [String: JSON]
    
    typealias Result = Int?
    
    var errorCode: Result {
        guard request.headers.contains("Host")  else {
            return Response.badRequest.statusCode
        }
        
        guard let _ = request.httpMethod() else {
            return Response.unsopportedMethod.statusCode
        }
        
        guard request.hasWrongOrMissingContentType() && request.isPayloadRequired() else {
                return nil
        }

        return Response.unsupportedMediaType.statusCode
    }
}
