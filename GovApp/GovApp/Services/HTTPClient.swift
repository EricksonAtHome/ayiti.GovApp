import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Transport-level failures. Services translate these into `AppError`, because
/// what a 401 means depends on which endpoint returned it.
enum HTTPFailure: Error, Equatable {
    case status(Int)
    /// The response was not JSON. `id.ayiti.io` answers unknown paths with its
    /// single-page-app HTML shell, so a `text/html` body must never be treated
    /// as a successful API response.
    case notJSON(contentType: String?)
    case decoding
    case transport
    case canceled
}

/// Thin `URLSession` wrapper: JSON in, JSON out, with strict content-type
/// checking and a bounded timeout.
struct HTTPClient: Sendable {
    private let session: URLSession

    init(timeout: TimeInterval = 20) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2
        configuration.httpAdditionalHeaders = ["Accept": "application/json"]
        session = URLSession(configuration: configuration)
    }

    func get<Response: Decodable>(_ url: URL, as: Response.Type = Response.self) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return try await perform(request)
    }

    func post<Body: Encodable, Response: Decodable>(
        _ url: URL,
        body: Body,
        as: Response.Type = Response.self
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        return try await perform(request)
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw HTTPFailure.canceled
        } catch {
            throw HTTPFailure.transport
        }

        guard let http = response as? HTTPURLResponse else {
            throw HTTPFailure.transport
        }
        guard (200..<300).contains(http.statusCode) else {
            throw HTTPFailure.status(http.statusCode)
        }

        let contentType = http.value(forHTTPHeaderField: "Content-Type")
        guard contentType?.localizedCaseInsensitiveContains("json") == true else {
            throw HTTPFailure.notJSON(contentType: contentType)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw HTTPFailure.decoding
        }
    }
}
