// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

extension Request {
    func normalizedURL() -> String? {
        requestHeaders().first?
            .components(separatedBy: " ")
            .get(at: 1)?
            .trimInitialAndLastSlashes()
    }
    
    func requestHeaders() -> [String] {
        headers.components(separatedBy: "\n")
    }
    
    func urlComponents() -> [String] {
        Array(normalizedURL()?.components(separatedBy: "/") ?? [])
    }
    
    func id() -> String? {
        urlComponents().get(at: 1)
    }
    
    func payloadAsJSONItem() -> JSONItem? {
        JSONCoder.decode(body)
    }
    
    func payloadJSONHasID() -> Bool {
        payloadAsJSONItem()?.keys.contains("id") ?? false
    }
    
    func payloadIsInvalidOrEmptyJSON() -> Bool {
        !payloadIsValidNonEmptyJSON()
    }
    
    func payloadIsValidNonEmptyJSON() -> Bool {
        JSONValidator.isValidJSON(body) && !JSONValidator
            .isEmptyJSON(body)
    }
    
    func urlHasNotId() -> Bool {
        route().id == nil
    }

    
    func collectionName() -> String? {
        urlComponents().first
    }
    
    enum HTTPMethod: String {
        case GET
        case POST
        case DELETE
        case PUT
        case PATCH
    }
    
    func httpMethod() -> HTTPMethod? {
        guard let verb = requestHeaders().first?.components(separatedBy: " ").first else {
            return nil
        }
        return HTTPMethod(rawValue: verb)
    }
    
    func isPayloadRequired() -> Bool {
        [HTTPMethod.PUT, .PATCH, .POST].contains(httpMethod())
    }
    
    func allItems() -> Bool {
        urlComponents().count == 1
    }
    
    enum ResourceRoute {
        case collection(name: String)
        case item(id: String, collectionName: String)
        case subroute
        
        init(_ urlComponents: [String]) {
            switch urlComponents.count {
            case 1: self = .collection(name: urlComponents[0])
            case 2: self = .item(id: urlComponents[1], collectionName: urlComponents[0])
            default: self = .subroute
            }
        }
        
        var id: String? {
            if case let .item(id, _) = self {
                return id
            }
            return nil
        }
    }
    
    func route() -> ResourceRoute {
        ResourceRoute(urlComponents())
    }
    
    func hasWrongOrMissingContentType() -> Bool {
        guard let contentType = contentType() else {
            return true
        }
        
        return contentType != "application/json"
    }
    
    func contentType() -> String? {
        for line in requestHeaders() {
            if line.lowercased().starts(with: "content-type:") {
                return line
                    .dropFirst("content-type:".count)
                    .trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}
