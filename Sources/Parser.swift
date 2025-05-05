// Created by Cristian Felipe Patiño Rojas on 5/5/25.
import Foundation

public struct Parser {
    private let resources: [String: JSON]
    
    public init(resources: [String : JSON]) {
        self.resources = resources
    }
    
    public func parse(_ request: Request) -> Response {
        let validator = HeadersValidator(
            request: request,
            collections: resources
        )
        
        let router = Router(
            request: request,
            collections: resources
        )
        
        switch validator.result {
        case .success where request.collectionName() != nil:
            guard let response = router.handleRequest() else {
                let collectionName = request.collectionName()!
                switch request.method() {
                case .POST  : return handlePOST(request, on: collectionName)
                case .PUT   : return handlePUT(request, on: collectionName)
                case .PATCH where requestedResource(request) != nil:
                    return handlePATCH(
                        request,
                        on: collectionName,
                        for: requestedResource(request)!
                    )
                default: return Response(statusCode: 404)
                }
            }
            return response
        case .failure(let error):
            return Response(statusCode: error.rawValue)
        default: return Response(statusCode: 404)
        }
    }
    
    func requestedResource(_ request: Request) -> JSONItem? {
        guard
            let id = request.route().id,
            let collectionName = request.collectionName(),
            let existingItem = getItem(withId: id, on: collectionName)
        else { return nil }
        return existingItem
    }
}

// MARK: - POST
extension Parser {
    
    private func handlePOST(_ request: Request, on collection: String) -> Response {
        if let body = request.body, JSONUtils.isValidNonEmptyJSON(body) {
            var jsonItem: JSONItem? = try? JSONSerialization.jsonObject(with: body.data(using: .utf8)!, options: []) as? JSONItem
            let hasID = jsonItem?.keys.contains("id") ?? false
            let statusCode = hasID ? 400 : 201
            let existentItems = resources[collection] as? JSONArray ?? []
            let newId = existentItems.isEmpty ? 1 : existentItems.count
            jsonItem?["id"] = newId
            return Response(
                statusCode: statusCode,
                rawBody: JSONUtils.isValidJSON(body) && !hasID ? JSONUtils.jsonItemToString(jsonItem!) : nil
            )
        } else {
            return Response(statusCode: 400)
        }
    }
}

// MARK: - PUT
extension Parser {

    private func handlePUT(_ request: Request, on collection: String) -> Response {
        guard let id = request.id() else {
            return Response(statusCode: 400)
        }
        
        guard let _ = getItem(withId: id, on: collection) else {
            return Response(statusCode: 200, rawBody: request.body)
        }
        
        guard
            let body = request.body,
            JSONUtils.isValidNonEmptyJSON(body),
            let bodyId = JSONUtils.jsonItem(from: body)?["id"] as? String,
            bodyId == id
        else {
            return Response(statusCode: 400)
        }
        
       return Response(statusCode: 200, rawBody: body)
    }
}

// MARK: - Patch
extension Parser {

    func handlePATCH(_ request: Request, on collection: String, for existingItem: JSONItem) -> Response {
        guard
            let body = request.body,
            JSONUtils.isValidNonEmptyJSON(body),
            let patch = JSONUtils.jsonItem(from: body)
        else {
            return Response(statusCode: 400)
        }
        
        if let bodyId = patch["id"] as? String {
            if bodyId == existingItem["id"] as? String {
                return Response(statusCode: 200, rawBody: body)
            }
            else {
                return Response(statusCode: 400)
            }
        }
        
        let patchedItem = existingItem * { item in
            for (key, value) in patch {
                item[key] = value
            }
        }

        let updatedJSON = JSONUtils.jsonItemToString( patchedItem)
        return Response(statusCode: 200, rawBody: updatedJSON, contentLength: updatedJSON?.contentLenght())
    }
}


enum JSONUtils {
    static func jsonToString(_ json: JSON) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: json) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func jsonItemToString(_ item: JSONItem) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: item) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func isValidJSON(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }
    
    
    static func jsonItem(from string: String) -> JSONItem? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? JSONItem
    }
    
    static func isValidNonEmptyJSON(_ body: String?) -> Bool {
        guard let body = body, JSONUtils.isValidJSON(body) else { return false }
        return body.removingSpaces().removingBreaklines() != "{}"
    }
}

// MARK: - Helpers
extension Parser {
    
    private func rawBody(for collectionName: String) -> String? {
        guard let items = resources[collectionName] else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: items) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func getItem(withId id: String, on collection: String) -> JSONItem? {
        let items = resources[collection] as? JSONArray
        let item = items?.getItem(with: id)
        return item
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
        typealias Item = (id: String, collectionName: String)
        case collection(name: String)
        case resource(Item)
        case nestedSubroute
        
        init(_ urlComponents: [String]) {
            switch urlComponents.count {
            case 1: self = .collection(name: urlComponents[0])
            case 2: self = .resource((id: urlComponents[1], collectionName: urlComponents[0]))
            default: self = .nestedSubroute
            }
        }
        
        var id: String? {
            if case let .resource(item) = self {
                return item.id
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


extension String {
    func contentLenght() -> Int {
        data(using: .utf8)?.count ?? count
    }
    
    fileprivate func removingBreaklines() -> String {
        self.replacingOccurrences(of: "\n", with: "")
    }
    
    fileprivate func removingSpaces() -> String {
        self.replacingOccurrences(of: " ", with: "")
    }
    
    fileprivate func trimInitialAndLastSlashes() -> String {
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
