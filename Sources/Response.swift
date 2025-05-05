// Created by Cristian Felipe Patiño Rojas on 5/5/25.


public struct Response: Equatable {
    public let statusCode: Int
    public let headers: [String: String]
    public let rawBody: String?
    
    public init(statusCode: Int, headers: [String : String], rawBody: String?) {
        self.statusCode = statusCode
        self.headers = headers
        self.rawBody = rawBody
    }
}
