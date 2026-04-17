import Foundation

extension RatingLevel {
    var requiredLevels: [RatingLevel] {
        switch self {
        case .s1: return [.s1]
        case .s2: return [.s1, .s2]
        case .s3: return [.s1, .s2, .s3]
        case .c1: return [.s1, .s2, .s3, .c1]
        }
    }

    var displayName: String {
        switch self {
        case .s1: return "S1 – Delivery + Ground"
        case .s2: return "S2 – Tower"
        case .s3: return "S3 – Approach/Departure"
        case .c1: return "C1 – Enroute"
        }
    }

    var sectionTitle: String {
        switch self {
        case .s1: return "Delivery + Ground"
        case .s2: return "Tower"
        case .s3: return "Approach/Departure"
        case .c1: return "Enroute"
        }
    }

    /// Default passing threshold — may be overridden by ExamSection in SwiftData.
    var defaultPassingThreshold: Double {
        switch self {
        case .s1: return 0.80
        case .s2: return 0.90
        case .s3: return 0.80
        case .c1: return 0.85
        }
    }

    var orderIndex: Int {
        switch self {
        case .s1: return 0
        case .s2: return 1
        case .s3: return 2
        case .c1: return 3
        }
    }

    var scopeDescription: String {
        switch self {
        case .s1: return "S1 criteria only."
        case .s2: return "S1 and S2 criteria."
        case .s3: return "S1, S2, and S3 criteria."
        case .c1: return "S1, S2, S3, and C1 criteria."
        }
    }
}
