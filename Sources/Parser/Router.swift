// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

struct Router {
    let request: Request
    let collections: [String: JSON]
    let idGenerator: () -> String
    func handleRequest() -> Response {
        switch request.httpMethod() {
        case
                .PUT   where request.payloadIsInvalidOrEmptyJSON(),
                .POST  where request.payloadIsInvalidOrEmptyJSON(),
                .PATCH where request.payloadIsInvalidOrEmptyJSON(),
            
                .PUT   where request.payloadJSONHasID(),
                .POST  where request.payloadJSONHasID(),
                .PATCH where request.payloadJSONHasID(),
            
                .DELETE where request.urlHasNotId(),
                .PATCH  where request.urlHasNotId():
            
            return .badRequest
            
        case .GET   : return handleGET()
        case .DELETE: return handleDELETE()
        case .PUT   : return handlePUT()
        case .POST  : return handlePOST()
        case .PATCH : return handlePATCH()
        default: return Response(statusCode: 405)
        }
    }
    
    private func handleGET() -> Response {
        switch request.route() {
        case let .item(id, collection) where !itemExists(id, collection):
            return .notFound
        case let .collection(name) where !collectionExists(name):
            return .notFound
        case let .collection(name):
            return .OK(collections[name] | JSONUtils.jsonToString)
        case let .item(id, collection) where itemExists(id, collection):
            return .OK(getItem(id, on: collection) | JSONUtils.jsonItemToString)
            
        default: return .badRequest
        }
    }
    
    private func handleDELETE() -> Response {
        switch request.route() {
        case .collection, .subroute:
            return .badRequest
        case let .item(id, collection) where !itemExists(id, collection):
            return .notFound
        case .item:
            return .empty
        }
    }
    
    private func handlePUT() -> Response {
        switch request.route() {
        case let .item(id, collection) where !itemExists(id, collection):
            return .OK
        case .item where request.body.isEmpty:
            return .badRequest
        case .item where request.payloadIsValidNonEmptyJSON():
            return .OK(request.body)
        default:
            return .badRequest
        }
    }
    
    private func handlePOST() -> Response {
        switch request.route() {
        case .item: return .badRequest
        case let .collection(name) where !collectionExists(name):
            return .notFound
        case .collection:
            let jsonItem = request.payloadAsJSONItem() | { $0?["id"] = idGenerator() }
            return .created(jsonItem | JSONUtils.jsonItemToString)
        default: return .badRequest
        }
    }
    
    private func handlePATCH() -> Response {
        switch request.route() {
        case let .item(id, collection) where !itemExists(id, collection):
            return .notFound
        case let .item(id, collection):
            let patch = request.payloadAsJSONItem()!
            let item = getItem(id, on: collection)!
            
            let patched = item.applyPatch(patch) | JSONUtils.jsonToString
            return .OK(patched)
        default:
            return .badRequest
        }
    }
    
    private func getItem(_ id: String, on collection: String) -> JSONItem? {
        let items = collections[collection] as? JSONArray
        let item = items?.getItem(with: id)
        return item
    }

    private func collectionExists(_ collectionName: String) -> Bool {
        collections.keys.contains(collectionName)
    }
    
    private func containsItemId(_ body: String) -> Bool {
        JSONUtils.jsonItem(from: body)?.keys.contains("id") ?? false
    }
    
    private func itemExists(_ id: String, _ collectionName: String) -> Bool {
        (collections[collectionName] as? JSONArray)?.getItem(with: id) != nil
    }
    
    private func jsonArray(_ collection: String) -> JSONArray? {
        collections[collection] as? JSONArray
    }
}
