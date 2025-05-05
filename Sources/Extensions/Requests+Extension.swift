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
    
    func collectionName() -> String? {
        urlComponents().first
    }
    
    enum HTTPVerb: String {
        case GET
        case POST
        case DELETE
        case PUT
        case PATCH
    }
    
    func method() -> HTTPVerb? {
        guard let verb = requestHeaders().first?.components(separatedBy: " ").first else {
            return nil
        }
        return HTTPVerb(rawValue: verb)
    }
    
    func payloadRequiredRequest() -> Bool {
        [HTTPVerb.PUT, .PATCH, .POST].contains(method())
    }
    
    func allItems() -> Bool {
        urlComponents().count == 1
    }
    
    enum RequestType {
        case collection(name: String)
        case resource(id: String, collectionName: String)
        case nestedSubroute
        
        init(_ urlComponents: [String]) {
            switch urlComponents.count {
            case 1: self = .collection(name: urlComponents[0])
            case 2: self = .resource(id: urlComponents[1], collectionName: urlComponents[0])
            default: self = .nestedSubroute
            }
        }
        
        var id: String? {
            if case let .resource(id, _) = self {
                return id
            }
            return nil
        }
    }
    
    func route() -> RequestType {
        RequestType(urlComponents())
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
