// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

struct Router {
    let request: Request
    let collections: [String: JSON]
    func handleRequest() -> Response {
        switch request.method() {
        case
                .PUT   where !request.payloadIsValidNonEmptyJSON(),
                .POST  where !request.payloadIsValidNonEmptyJSON(),
                .PATCH where !request.payloadIsValidNonEmptyJSON(),
            
                .PUT   where request.payloadJSONHasID(),
                .POST  where request.payloadJSONHasID(),
                .PATCH where request.payloadJSONHasID():
            
            return Response(statusCode: 400)
            
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
            return Response(statusCode: 404)
        case let .collection(name) where !collectionExists(name):
            return Response(statusCode: 404)
            
        case let .collection(name):
            let collection = collections[name].flatMap(JSONUtils.jsonToString)
            return Response(
                statusCode: 200,
                rawBody: collection,
                contentLength: collection?.contentLenght()
            )
        case let .resource(id, collection) where itemExists(id, collection):
            let item = jsonArray(collection)?.getItem(with: id).flatMap(JSONUtils.jsonItemToString)
            return Response(
                statusCode: 200,
                rawBody: item,
                contentLength: item?.contentLenght()
            )
            
        default: return Response(statusCode: 400)
        }
    }
    
    private func handleDELETE() -> Response {
        switch request.route() {
        case .collection, .nestedSubroute:
            return Response(statusCode: 400)
        case let .resource(id, collection) where !itemExists(id, collection):
            return Response(statusCode: 404)
        case .resource:
            return Response(statusCode: 204)
        }
    }
    
    private func handlePUT() -> Response {
        switch request.route() {
        case let .resource(id, collection) where !itemExists(id, collection):
            return Response(statusCode: 200)
        case .resource where request.body == nil:
            return Response(statusCode: 400)
        case .resource where request.payloadIsValidNonEmptyJSON():
            return Response(
                statusCode: 200,
                rawBody:  request.body,
                contentLength: request.body?.contentLenght()
            )
        default:
            return Response(statusCode: 400)
        }
    }
    
    private func handlePOST() -> Response {
        switch request.route() {
        case .resource: return Response(statusCode: 400)
        case let .collection(name) where !collectionExists(name):
            return Response(statusCode: 404)
        case let .collection(name):
            let jsonItem = request.payloadAsJSONItem() * { $0?["id"] = generateID(forCollection: name) }
            return Response(
                statusCode: 201,
                rawBody: jsonItem.flatMap(JSONUtils.jsonItemToString),
                contentLength: jsonItem.flatMap(JSONUtils.jsonItemToString)?.contentLenght()
            )
        default: return Response(statusCode: 400)
        }
    }
    
    #warning("Use uuid")
    private func generateID(forCollection name: String) -> String {
        ((collections[name] as? JSONArray ?? []).count + 1).description
    }
    
    private func handlePATCH() -> Response {
        switch request.route() {
        case let .resource(id, collection) where !itemExists(id, collection):
            return Response(statusCode: 404)
        case let .resource(id, collection):
            let patch = request.payloadAsJSONItem()!
            let item = getItem(withId: id, on: collection)!
            
            let patched = item.applyPatch(patch) * JSONUtils.jsonToString
            
            return Response(
                statusCode: 200,
                rawBody: patched,
                contentLength: patched?.contentLenght()
            )
        default:
            return Response(statusCode: 400)
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
