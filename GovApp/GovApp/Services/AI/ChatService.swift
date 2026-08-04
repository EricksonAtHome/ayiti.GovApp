import Foundation

protocol ChatService: Sendable {
    func reply(to prompt: String, history: [ChatMessage]) async throws -> String
    /// Probed once when the chat screen appears so the citizen sees an offline
    /// notice instead of a failure on their first message.
    func isReachable() async -> Bool
}

/// Client for the ElloFive FRC bridge — see the skill's AI.md.
///
/// The bridge has no authentication, so nothing from `Session` and no other
/// personal data may be sent in a prompt.
struct EllofiveClient: ChatService {
    private struct RunRequest: Encodable {
        let input: String
    }

    private struct RunResponse: Decodable {
        let output: String
        let status: String?
        let model: String?
        let latencyMs: Int?
    }

    private struct HealthResponse: Decodable {
        let ok: Bool
        let models: [String]?
    }

    let config: AppConfig
    let http: HTTPClient

    init(config: AppConfig = .current, http: HTTPClient = HTTPClient(timeout: 60)) {
        self.config = config
        self.http = http
    }

    func reply(to prompt: String, history: [ChatMessage]) async throws -> String {
        let input = PromptBuilder(contextTurns: config.contextTurns)
            .build(prompt: prompt, history: history)

        let response: RunResponse
        do {
            response = try await http.post(config.runURL, body: RunRequest(input: input))
        } catch let failure as HTTPFailure {
            throw Self.appError(for: failure)
        }

        let output = response.output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else { throw AppError.assistantUnavailable }
        return output
    }

    func isReachable() async -> Bool {
        let response: HealthResponse? = try? await http.get(config.healthURL)
        return response?.ok == true
    }

    static func appError(for failure: HTTPFailure) -> AppError {
        switch failure {
        case .transport:
            .network
        case .canceled:
            .canceled
        // 502 is the bridge telling us Ollama itself is down; 503 is the bridge
        // failing its own health check. Both read the same to a citizen.
        case .status, .notJSON, .decoding:
            .assistantUnavailable
        }
    }
}

/// Deterministic double for previews and tests. Never reaches the network.
struct StubChatService: ChatService {
    var canned = "Paspò ou an pare pou w vin chèche l nan biwo imigrasyon an."
    var delay: Duration = .milliseconds(400)
    var reachable = true

    func reply(to prompt: String, history: [ChatMessage]) async throws -> String {
        try? await Task.sleep(for: delay)
        guard reachable else { throw AppError.assistantUnavailable }
        return canned
    }

    func isReachable() async -> Bool { reachable }
}
