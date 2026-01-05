import Foundation

struct YeelightResponse {
    let id: Int?
    let result: [Any]?
    let error: YeelightError?
    let method: String?
    let params: [String: Any]?

    var isSuccess: Bool {
        error == nil && result != nil
    }

    var isNotification: Bool {
        method != nil
    }

    static func parse(_ data: Data) -> YeelightResponse? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let id = json["id"] as? Int
        let result = json["result"] as? [Any]
        let method = json["method"] as? String
        let params = json["params"] as? [String: Any]

        var error: YeelightError?
        if let errorDict = json["error"] as? [String: Any] {
            let code = errorDict["code"] as? Int ?? -1
            let message = errorDict["message"] as? String ?? "Unknown error"
            error = YeelightError(code: code, message: message)
        }

        return YeelightResponse(
            id: id,
            result: result,
            error: error,
            method: method,
            params: params
        )
    }

    func propertiesAsDictionary(for props: [String]) -> [String: Any] {
        guard let result = result else { return [:] }

        var dict: [String: Any] = [:]
        for (index, prop) in props.enumerated() {
            if index < result.count {
                dict[prop] = result[index]
            }
        }
        return dict
    }
}

struct YeelightError: Error {
    let code: Int
    let message: String

    var localizedDescription: String {
        "Yeelight Error \(code): \(message)"
    }
}

// Common error codes
extension YeelightError {
    static let unsupportedMethod = -1
    static let invalidParams = -2
    static let invalidCommand = -3
}
