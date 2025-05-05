// Created by Cristian Felipe Patiño Rojas on 5/5/25.


import Foundation

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
        return df
    }
}
