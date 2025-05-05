// Created by Cristian Felipe Patiño Rojas on 5/5/25.
import Foundation

public struct Parser {
    private let collections: [String: JSON]
    
    public init(collections: [String : JSON]) {
        self.collections = collections
    }
    
    public func parse(_ request: Request) -> Response {
        let validator = HeadersValidator(
            request: request,
            collections: collections
        )
        
        let router = Router(
            request: request,
            collections: collections
        )
        
        switch validator.result {
        case .none:
            return router.handleRequest()
        case let .some(errorCode):
            return Response(statusCode: errorCode)
        }
    }
}
