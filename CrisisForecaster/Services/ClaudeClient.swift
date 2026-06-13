import Foundation

/// Raw URLSession client for the Anthropic Messages API. Swift has no official
/// Anthropic SDK, so we build requests by hand.
///
/// Targets `claude-opus-4-8`:
///  - No `temperature` param (rejected on 4.7+).
///  - No assistant prefill — structured output via `output_config.format` instead.
///  - Adaptive thinking is optional and left off (omitting `thinking` is valid).
///  - Still handle `stop_reason == "refusal"` defensively before reading content.
struct ClaudeClient: Sendable {
    enum ClaudeError: LocalizedError {
        case missingAPIKey
        case refusal(category: String?)
        case http(status: Int, body: String)
        case emptyResponse
        case decoding(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                "No Anthropic API key. Set ANTHROPIC_API_KEY in Config/Secrets.xcconfig."
            case .refusal(let category):
                "Claude declined this request\(category.map { " (\($0))" } ?? "")."
            case .http(let status, let body):
                "Claude API error \(status): \(body)"
            case .emptyResponse:
                "Claude returned no text content."
            case .decoding(let detail):
                "Couldn't parse Claude's response: \(detail)"
            }
        }
    }

    private let model = "claude-opus-4-8"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private var apiKey: String? {
        let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String
        guard let key, !key.isEmpty, key != "sk-ant-REPLACE_ME" else { return nil }
        return key
    }

    // MARK: Public

    /// Structured-output call: Claude is constrained to `jsonSchema` and the first
    /// text block is decoded into `T`.
    func completeJSON<T: Decodable>(
        system: String,
        user: String,
        jsonSchema: [String: Any],
        maxTokens: Int = 2000,
        as type: T.Type = T.self
    ) async throws -> T {
        var body = baseBody(system: system, user: user, maxTokens: maxTokens)
        body["output_config"] = [
            "effort": "medium",
            "format": ["type": "json_schema", "schema": jsonSchema],
        ]
        let text = try await send(body)
        guard let data = text.data(using: .utf8) else { throw ClaudeError.emptyResponse }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ClaudeError.decoding(error.localizedDescription)
        }
    }

    /// Plain-text call (used for the Emergency Passport markdown).
    func completeText(
        system: String,
        user: String,
        maxTokens: Int = 2000
    ) async throws -> String {
        var body = baseBody(system: system, user: user, maxTokens: maxTokens)
        body["output_config"] = ["effort": "medium"]
        return try await send(body)
    }

    // MARK: Internal

    private func baseBody(system: String, user: String, maxTokens: Int) -> [String: Any] {
        [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [["role": "user", "content": user]],
        ]
    }

    /// Sends the request, validates `stop_reason`, and returns concatenated text blocks.
    private func send(_ body: [String: Any]) async throws -> String {
        guard let apiKey else { throw ClaudeError.missingAPIKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ClaudeError.http(status: -1, body: "No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "<binary>"
            throw ClaudeError.http(status: http.statusCode, body: bodyText)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        // A "refusal" stop_reason on the final response means the whole chain (Fable 5
        // + fallback) declined. Surface it before we try to read content.
        if let stop = json["stop_reason"] as? String, stop == "refusal" {
            let category = (json["stop_details"] as? [String: Any])?["category"] as? String
            throw ClaudeError.refusal(category: category)
        }

        let blocks = json["content"] as? [[String: Any]] ?? []
        let text = blocks
            .filter { ($0["type"] as? String) == "text" }
            .compactMap { $0["text"] as? String }
            .joined()

        guard !text.isEmpty else { throw ClaudeError.emptyResponse }
        return text
    }
}
