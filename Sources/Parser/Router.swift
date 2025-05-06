// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

struct Router {
    let request: Request
    let collections: [String: JSON]
    let idGenerator: () -> String
    func handleRequest() -> Response {
        switch request.method() {
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
        case let .resource(id, collection) where !itemExists(id, collection):
            return .notFound
        case let .collection(name) where !collectionExists(name):
            return .notFound
        case let .collection(name):
            let collection = collections[name].flatMap(JSONUtils.jsonToString)
            return .OK(collection)
        case let .resource(id, collection) where itemExists(id, collection):
            let item = jsonArray(collection)?.getItem(with: id).flatMap(JSONUtils.jsonItemToString)
            return .OK(item)
            
        default: return .badRequest
        }
    }
    
    private func handleDELETE() -> Response {
        switch request.route() {
        case .collection, .nestedSubroute:
            return .badRequest
        case let .resource(id, collection) where !itemExists(id, collection):
            return .notFound
        case .resource:
            return .empty
        }
    }
    
    private func handlePUT() -> Response {
        switch request.route() {
        case let .resource(id, collection) where !itemExists(id, collection):
            return .OK
        case .resource where request.body.isEmpty:
            return .badRequest
        case .resource where request.payloadIsValidNonEmptyJSON():
            return .OK(request.body)
        default:
            return .badRequest
        }
    }
    
    private func handlePOST() -> Response {
        switch request.route() {
        case .resource: return .badRequest
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
        case let .resource(id, collection) where !itemExists(id, collection):
            return .notFound
        case let .resource(id, collection):
            let patch = request.payloadAsJSONItem()!
            let item = getItem(withId: id, on: collection)!
            
            let patched = item.applyPatch(patch) | JSONUtils.jsonToString
            return .OK(patched)
        default:
            return .badRequest
        }
    }
    
    private func getItem(withId id: String, on collection: String) -> JSONItem? {
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
