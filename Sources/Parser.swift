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


func *<T>(lhs: T, rhs: (inout T) -> Void) -> T {
    var copy = lhs
    rhs(&copy)
    return copy
}







