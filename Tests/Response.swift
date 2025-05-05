// Created by Cristian Felipe Patiño Rojas on 5/5/25.


struct Response: Equatable {
    let statusCode: Int
    let headers: [String: String]
    let rawBody: String?
}
