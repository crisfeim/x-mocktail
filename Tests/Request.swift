// Created by Cristian Felipe Patiño Rojas on 5/5/25.


struct Request {
    let headers: String
    let body: String?

    init(headers: String, body: String? = nil) {
        self.headers = headers
        self.body = body
    }
}
