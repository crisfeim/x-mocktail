// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

struct Router {
    let request: Request
    let collections: [String: JSON]
    func handleRequest() -> Response? {
        switch request.method() {
        case .GET: return handleGET()
        case .DELETE: return handleDELETE()
        case .PUT: return handlePUT()
        case .POST: return handlePOST()
        default: return nil
        }
    }
    
    private func handleGET() -> Response? {
        switch request.route() {
        case let .collection(name) where !collectionExists(name):
            return Response(statusCode: 404)
        case let .collection(name) where collectionIsEmpty(name):
            return Response(
                statusCode: 200,
                rawBody: "[]",
                contentLength: "[]".contentLenght()
            )
        case let .collection(name) where !collectionIsEmpty(name):
            let body = collections[name].flatMap(JSONUtils.jsonToString)
            return Response(
                statusCode: 200,
                rawBody: body,
                contentLength: body?.contentLenght()
            )
        case let .resource(item) where itemExists(item):
            let body = (collections[item.collectionName] as? JSONArray)?.getItem(with: item.id).flatMap(JSONUtils.jsonItemToString)
            return Response(
                statusCode: 200,
                rawBody: body,
                contentLength: body?.contentLenght()
            )
        default: return nil
        }
    }
    
    private func handleDELETE() -> Response? {
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
    
    private func handlePOST() -> Response? {
        switch request.route() {
        case .resource: return Response(statusCode: 400)
        default: return nil
        }
    }

    private func collectionExists(_ collectionName: String) -> Bool {
        collections.keys.contains(collectionName)
    }
    
    private func collectionIsEmpty(_ collectionName: String) -> Bool {
        let collection = collections[collectionName] as? JSONArray
        return collection?.isEmpty ?? true
    }
    
    private func itemExists(_ item: (id: String, collectionName: String)) -> Bool {
        (collections[item.collectionName] as? JSONArray)?.getItem(with: item.id) != nil
    }
}
