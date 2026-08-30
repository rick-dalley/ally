import Foundation

// Same API shape as WearableApiClient (Linux) and WearDataLayerClient (Wear OS) —
// fetchSync/acknowledge/acknowledgeAll/panic — so the three watch apps' screens read
// almost identically despite three different transports underneath.
enum WearableClient {
    private static let patientKey = "patient_uuid"

    static func getPatientUuid() -> String? {
        UserDefaults.standard.string(forKey: patientKey)
    }

    static func setPatientUuid(_ uuid: String) {
        UserDefaults.standard.set(uuid, forKey: patientKey)
    }

    static func isPaired() -> Bool {
        getPatientUuid() != nil
    }

    private static func decode(_ json: String) throws -> [String: Any] {
        guard let data = json.data(using: .utf8),
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WatchConnectivityError.remote("Malformed response from Ally")
        }
        return object
    }

    static func fetchSync() async throws -> [String: Any] {
        guard let patientUuid = getPatientUuid() else { throw WatchConnectivityError.remote("Not paired yet") }
        let json = try await WatchConnectivityClient.shared.send(method: "sync", arguments: patientUuid)
        return try decode(json)
    }

    static func acknowledge(type: String, id: String) async throws -> [String: Any] {
        guard let patientUuid = getPatientUuid() else { throw WatchConnectivityError.remote("Not paired yet") }
        let body = try JSONSerialization.data(withJSONObject: ["patientUuid": patientUuid, "type": type, "id": id])
        let json = try await WatchConnectivityClient.shared.send(method: "ack", arguments: String(data: body, encoding: .utf8))
        return try decode(json)
    }

    static func acknowledgeAll() async throws -> [String: Any] {
        guard let patientUuid = getPatientUuid() else { throw WatchConnectivityError.remote("Not paired yet") }
        let body = try JSONSerialization.data(withJSONObject: ["patientUuid": patientUuid])
        let json = try await WatchConnectivityClient.shared.send(method: "ackAll", arguments: String(data: body, encoding: .utf8))
        return try decode(json)
    }

    static func panic(trigger: String) async throws -> Int {
        guard let patientUuid = getPatientUuid() else { throw WatchConnectivityError.remote("Not paired yet") }
        let body = try JSONSerialization.data(withJSONObject: ["patientUuid": patientUuid, "trigger": trigger])
        let json = try await WatchConnectivityClient.shared.send(method: "panic", arguments: String(data: body, encoding: .utf8))
        let result = try decode(json)
        return result["notified"] as? Int ?? 0
    }

    static func setMood(index: Int) async throws -> [String: Any] {
        guard let patientUuid = getPatientUuid() else { throw WatchConnectivityError.remote("Not paired yet") }
        let body = try JSONSerialization.data(withJSONObject: ["patientUuid": patientUuid, "moodIndex": index])
        let json = try await WatchConnectivityClient.shared.send(method: "setMood", arguments: String(data: body, encoding: .utf8))
        return try decode(json)
    }

    static func flagSymptom(label: String) async throws -> [String: Any] {
        guard let patientUuid = getPatientUuid() else { throw WatchConnectivityError.remote("Not paired yet") }
        let body = try JSONSerialization.data(withJSONObject: ["patientUuid": patientUuid, "label": label])
        let json = try await WatchConnectivityClient.shared.send(method: "flagSymptom", arguments: String(data: body, encoding: .utf8))
        return try decode(json)
    }
}
