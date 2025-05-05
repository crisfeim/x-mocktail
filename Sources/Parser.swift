// Created by Cristian Felipe Patiño Rojas on 5/5/25.
import Foundation

public struct Parser {
    private let resources: [String: JSON]
    
    public init(resources: [String : JSON]) {
        self.resources = resources
    }
    
    public func parse(_ request: Request) -> Response {
        guard request.headers.contains("Host"), let collectionName = request.collectionName()  else {
            return Response(statusCode: 400)
        }
        
        guard let method = request.method() else {
            return Response(statusCode: 405)
        }
        
        guard resources.keys.contains(collectionName) else {
            return Response(statusCode: 404)
        }
        
        switch method {
        case .GET   : return handleGET(request, on: collectionName)
        case .DELETE: return handleDELETE(request, on: collectionName)
        case .POST  : return handlePOST(request, on: collectionName)
        case .PUT   : return handlePUT(request, on: collectionName)
        case .PATCH : return handlePATCH(request, on: collectionName)
        }
    }
    
}

// MARK: - GET
extension Parser {
    
    private func handleGET(_ request: Request, on collectionName: String) -> Response {
        
        switch request.type() {
        case .allResources where rawBody(for: collectionName) != nil:
            return Response(
                statusCode: 200,
                rawBody: rawBody(for: collectionName),
                contentLength: rawBody(for: collectionName)?.contentLenght()
            )
        case .singleResource(let id):
            guard let id = Int(id), let item = getItem(withId: id, on: collectionName) else { return Response(statusCode: 404) }
            
            let jsonString =  jsonString(of: item)
            return Response(
                statusCode: 200,
                rawBody: jsonString,
                contentLength: jsonString?.contentLenght()
            )
        default:
            return Response(statusCode: 404)
        }
    }
    
}
 

// MARK: - DELETE
extension Parser {
    private func handleDELETE(_ request: Request, on collection: String) -> Response {
        guard
            let idString = request.type().id,
            let id = Int(idString),
            let _ = getItem(withId: id, on: collection)
        else {
            return Response(statusCode: 404)
        }
        return Response(statusCode: 204)
    }
}

// MARK: - POST
extension Parser {
    
    private func handlePOST(_ request: Request, on collection: String) -> Response {
        guard let contentType = request.contentType(), contentType == "application/json" else {
            return Response(statusCode: 415)
        }
        
        if let body = request.body {
            guard !body.isEmpty, body.removingSpaces().removingBreaklines() != "{}" else { return Response(statusCode: 400) }
            var jsonItem: JSONItem? = try? JSONSerialization.jsonObject(with: body.data(using: .utf8)!, options: []) as? JSONItem
            let hasID = jsonItem?.keys.contains("id") ?? false
            let statusCode = hasID ? 400 : isValidJSON(body) ? 201 : 400
            let existentItems = resources[collection] as? JSONArray ?? []
            let newId = existentItems.isEmpty ? 1 : existentItems.count
            jsonItem?["id"] = newId
            return Response(
                statusCode: statusCode,
                rawBody: isValidJSON(body) && !hasID ? jsonString(of: jsonItem!) : nil
            )
        }
        return Response(statusCode: 415)
    }
}

// MARK: - PUT
extension Parser {

    private func handlePUT(_ request: Request, on collection: String) -> Response {
        guard let contentType = request.contentType(), contentType == "application/json" else {
            return Response(statusCode: 415)
        }
        
        guard let itemIdString = request.id(), let id = Int(itemIdString), let _ = getItem(withId: id, on: collection) else {
            return Response(statusCode: 404)
        }
        
        if let body = request.body, isValidJSON(body), body.removingSpaces().removingBreaklines() != "{}" {
            if let bodyId = jsonItem(from: body)?["id"] as? Int {
                if bodyId == id {
                    return Response(statusCode: 200, rawBody: body)
                }
                else {
                    return Response(statusCode: 400)
                }
            }
    
            return Response(
                statusCode: 200,
                rawBody: body
            )
        }
        return Response(statusCode: 400)
    }
}

// MARK: - Patch
extension Parser {
    func handlePATCH(_ request: Request, on collection: String) -> Response {
        guard let contentType = request.contentType(), contentType == "application/json" else {
            return Response(statusCode: 415)
        }

        guard let idString = request.type().id, let id = Int(idString) else {
            return Response(statusCode: 404)
        }

        guard var existingItem = getItem(withId: id, on: collection) else {
            return Response(statusCode: 404)
        }

        guard let patchBody = request.body, let patchData = patchBody.data(using: .utf8),
              let patch = try? JSONSerialization.jsonObject(with: patchData, options: []) as? JSONItem else {
            return Response(statusCode: 400)
        }

        for (key, value) in patch {
            existingItem[key] = value
        }

        let updatedJSON = jsonString(of: existingItem)
        return Response(statusCode: 200, rawBody: updatedJSON, contentLength: updatedJSON?.contentLenght())
    }
}



// MARK: - Helpers
extension Parser {
    
    private func rawBody(for collectionName: String) -> String? {
        guard let items = resources[collectionName] else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: items) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func getItem(withId id: Int, on collection: String) -> JSONItem? {
        let items = resources[collection] as? JSONArray
        let item = items?.getItem(with: id)
        return item
    }
    
    private func jsonString(of item: JSONItem) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: item) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func jsonItem(from string: String) -> JSONItem? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? JSONItem
    }
    
    func isValidJSON(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }
}

public extension Response {
    init(
        statusCode: Int,
        rawBody: String? = nil,
        contentLength: Int? = nil
    ) {
        let date = Self.dateFormatter.string(from: Date())
        
        let headers = [
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, HEAD, PUT, PATCH, POST, DELETE",
            "Access-Control-Allow-Headers": "content-type",
            "Content-Type": "application/json",
            "Date": date,
            "Connection": "close",
            "Content-Length": contentLength?.description
        ].compactMapValues { $0 }
        
        self.init(statusCode: statusCode, headers: headers, rawBody: rawBody)
    }
    
    static let dateFormatter = DateFormatter() * { df in
        df.dateFormat = "EEE',' dd MMM yyyy HH:mm:ss zzz"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
    }
}

private func *<T>(lhs: T, rhs: (inout T) -> Void) -> T {
    var copy = lhs
    rhs(&copy)
    return copy
}

private extension Request {
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
    
    func allItems() -> Bool {
        urlComponents().count == 1
    }
    
    enum RequestType {
        case allResources
        case singleResource(id: String)
        case subroute
        
        init(_ urlComponents: [String]) {
            switch urlComponents.count {
            case 1: self = .allResources
            case 2: self = .singleResource(id: urlComponents[1])
            default: self = .subroute
            }
        }
        
        var id: String? {
            if case let .singleResource(id) = self {
                return id
            }
            return nil
        }
    }
    
    func type() -> RequestType {
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


private extension String {
    func contentLenght() -> Int {
        data(using: .utf8)?.count ?? count
    }
    
    func removingBreaklines() -> String {
        self.replacingOccurrences(of: "\n", with: "")
    }
    
    func removingSpaces() -> String {
        self.replacingOccurrences(of: " ", with: "")
    }
    
    func trimInitialAndLastSlashes() -> String {
        var copy = self
        if copy.first == "/" {
            copy.removeFirst()
        }
        if copy.last == "/" {
            copy.removeLast()
        }
        
        return copy
    }
}

fileprivate extension Array {
    func get(at index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
