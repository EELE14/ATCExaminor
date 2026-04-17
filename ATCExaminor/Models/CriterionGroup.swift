import Foundation
import SwiftData

@Model
class CriterionGroup {
    var id: UUID
    var label: String
    var orderIndex: Int
    var criteria: [String]

    init(label: String, orderIndex: Int, criteria: [String] = []) {
        self.id = UUID()
        self.label = label
        self.orderIndex = orderIndex
        self.criteria = criteria
    }
}
