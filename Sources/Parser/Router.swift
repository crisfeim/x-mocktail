// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

struct Router {
    let request: Request
    let collections: [String: JSON]
    func handleRequest() -> Response {
        switch request.method() {
        case .GET: return handleGET()
        case .DELETE: return handleDELETE()
        case .PUT: return handlePUT()
        case .POST: return handlePOST()
        case .PATCH: return handlePATCH()
        default: return Response(statusCode: 405)
        }
    }
    
    private func handleGET() -> Response {
        switch request.route() {
        case let .collection(name) where !collectionExists(name):
            return Response(statusCode: 404)
        case let .collection(name):
            let collection = collections[name].flatMap(JSONUtils.jsonToString)
            return Response(
                statusCode: 200,
                rawBody: collection,
                contentLength: collection?.contentLenght()
            )
        case let .resource(item) where !itemExists(item):
            return Response(statusCode: 404)
        case let .resource(item) where itemExists(item):
            let body = (collections[item.collectionName] as? JSONArray)?.getItem(with: item.id).flatMap(JSONUtils.jsonItemToString)
            return Response(
                statusCode: 200,
                rawBody: body,
                contentLength: body?.contentLenght()
            )
        default: return Response(statusCode: 400)
        }
    }
    
    private func handleDELETE() -> Response {
        switch request.route() {
        case .collection, .nestedSubroute:
            return Response(statusCode: 400)
        case let .resource(item) where !itemExists(item):
            return Response(statusCode: 404)
        case .resource:
            return Response(statusCode: 204)
        }
    }
    
    private func handlePUT() -> Response {
        switch request.route() {
        case let .resource(item) where !itemExists(item):
            return Response(statusCode: 200)
        case .resource where request.body == nil:
            return Response(statusCode: 400)
        case .resource where JSONUtils.isValidJSON(request.body!):
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
        case .collection where !JSONUtils.isValidJSON(request.body!):
            return Response(statusCode: 400)
        case .collection where containsItemId(request.body!):
            return Response(statusCode: 400)
        case let .collection(name):
            var jsonItem: JSONItem? = try? JSONSerialization.jsonObject(with: request.body!.data(using: .utf8)!, options: []) as? JSONItem
            let newId = UUID().uuidString
            #warning("Use uuid")
            jsonItem?["id"] = (collections[name] as? JSONArray ?? []).count + 1
            
            
            return Response(
                statusCode: 201,
                rawBody: JSONUtils.jsonItemToString(jsonItem!),
                contentLength: JSONUtils.jsonItemToString(jsonItem!)?.contentLenght()
            )
        default: return Response(statusCode: 400)
        }
    }
    
    private func handlePATCH() -> Response {
        switch request.route() {
        case .collection     where !JSONUtils.isValidNonEmptyJSON(request.body),
             .resource       where !JSONUtils.isValidNonEmptyJSON(request.body),
             .nestedSubroute where !JSONUtils.isValidNonEmptyJSON(request.body),
             .resource       where hasID(request.body):
            return Response(statusCode: 400)
        case .resource(let item) where !itemExists(item):
            return Response(statusCode: 404)
        case .resource(let item):
            let patch = JSONUtils.jsonItem(from: request.body!)!
            let item = getItem(withId: item.id, on: item.collectionName)!
            let patched = item
            * { item in
                for (key, value) in patch {
                    item[key] = value
                }
            }
            * JSONUtils.jsonToString
            
            return Response(
                statusCode: 200,
                rawBody: patched,
                contentLength: patched?.contentLenght()
            )
        default:
            return Response(statusCode: 400)
        }
    }
    
    func hasID(_ body: String?) -> Bool {
        body == nil ? false : JSONUtils.jsonItem(from: body!)?.keys.contains("id") ?? false
    }
    
    func requestedResource(_ request: Request) -> JSONItem? {
        guard
            let id = request.route().id,
            let collectionName = request.collectionName(),
            let existingItem = getItem(withId: id, on: collectionName)
        else { return nil }
        return existingItem
    }
    
    private func getItem(withId id: String, on collection: String) -> JSONItem? {
        let items = collections[collection] as? JSONArray
        let item = items?.getItem(with: id)
        return item
    }

    private func collectionExists(_ collectionName: String) -> Bool {
        collections.keys.contains(collectionName)
    }
    
    private func collectionIsEmpty(_ collectionName: String) -> Bool {
        let collection = collections[collectionName] as? JSONArray
        return collection?.isEmpty ?? true
    }
    
    private func containsItemId(_ body: String) -> Bool {
        #warning("move to jsonutils")
        var jsonItem: JSONItem? = try? JSONSerialization.jsonObject(with: body.data(using: .utf8)!, options: []) as? JSONItem
        return jsonItem?.keys.contains("id") ?? false
    }
    
    private func itemExists(_ item: (id: String, collectionName: String)) -> Bool {
        (collections[item.collectionName] as? JSONArray)?.getItem(with: item.id) != nil
    }
}
