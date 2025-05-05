// Created by Cristian Felipe Patiño Rojas on 5/5/25.


public struct Request {
    public let headers: String
    public let body: String?

    public init(headers: String, body: String? = nil) {
        self.headers = headers
        self.body = body
    }
}
