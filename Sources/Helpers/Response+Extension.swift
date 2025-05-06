// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

extension Response {
    nonisolated(unsafe) static let badRequest = Response(statusCode: 400)
    nonisolated(unsafe) static let notFound = Response(statusCode: 404)
    nonisolated(unsafe) static let empty = Response(statusCode: 204)
    nonisolated(unsafe) static let OK = Response(statusCode: 200)
    
    static func created(_ rawBody: String?) -> Response {
        Response(statusCode: 201, rawBody: rawBody, contentLength: rawBody?.contentLenght())
    }
    
    static func OK(_ rawBody: String?) -> Response {
        Response(statusCode: 200, rawBody: rawBody, contentLength: rawBody?.contentLenght())
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
    
    static let dateFormatter = new(DateFormatter()) { df in
        df.dateFormat = "EEE',' dd MMM yyyy HH:mm:ss zzz"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
    }
}
