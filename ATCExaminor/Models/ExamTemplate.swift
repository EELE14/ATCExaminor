import Foundation
import SwiftData

struct ExamTemplate {

    struct SectionSeed {
        let level: RatingLevel
        let displayName: String
        let passingThreshold: Double
        let groups: [(label: String, criteria: [String])]
    }

    static let sections: [SectionSeed] = [
        SectionSeed(
            level: .s1,
            displayName: "Delivery + Ground",
            passingThreshold: 0.80,
            groups: [
                ("Delivery", [
                    "Ensures filed information is correct",
                    "Uses PFControl well and is organised",
                    "Issues IFR/VFR clearances correctly with proper phraseology",
                    "Confirms accurate readbacks from pilots"
                ]),
                ("Ground", [
                    "Provides taxi instructions with correct routing and hold short points",
                    "Manages pushback clearances safely and efficiently",
                    "Prevents runway/taxiway conflicts (incursion awareness)",
                    "Maintains situational awareness of all ground movements",
                    "Handles startup requests and sequencing logically",
                    "Uses concise, professional phraseology throughout"
                ])
            ]
        ),
        SectionSeed(
            level: .s2,
            displayName: "Tower",
            passingThreshold: 0.90,
            groups: [
                ("", [
                    "Sequences departures and arrivals effectively",
                    "Provides takeoff and landing clearances with proper timing",
                    "Applies runway separation standards (time/distance)",
                    "Manages go-arounds safely and efficiently",
                    "Handles missed approaches correctly",
                    "Maintains awareness of traffic in the circuit pattern",
                    "Provides wind, runway, and traffic advisories as needed",
                    "Ensures wake turbulence separation is applied",
                    "Manages simultaneous arrivals/departures when applicable",
                    "Uses correct phraseology and maintains clear communication"
                ])
            ]
        ),
        SectionSeed(
            level: .s3,
            displayName: "Approach/Departure",
            passingThreshold: 0.80,
            groups: [
                ("", [
                    "Identifies aircraft on radar after handoff from Tower",
                    "Provides accurate radar vectors for sequencing and separation",
                    "Applies vertical, lateral, and longitudinal separation standards",
                    "Manages STARs and SIDs correctly",
                    "Provides speed and altitude instructions for sequencing",
                    "Handles holding patterns when required",
                    "Ensures smooth handoffs to Enroute or Tower positions",
                    "Manages missed approaches and resequencing",
                    "Maintains situational awareness of all inbound/outbound traffic",
                    "Provides spacing for final approach sequencing",
                    "Coordinates with adjacent sectors for traffic flow",
                    "Uses correct phraseology and concise instructions"
                ])
            ]
        ),
        SectionSeed(
            level: .c1,
            displayName: "Enroute",
            passingThreshold: 0.85,
            groups: [
                ("", [
                    "Identifies aircraft after handoff from Approach/Departure",
                    "Provides climb/descent clearances with proper separation",
                    "Applies enroute separation standards (vertical, lateral, longitudinal)",
                    "Provides direct routings and shortcuts when possible",
                    "Manages sector traffic flow efficiently",
                    "Coordinates handoffs between adjacent sectors/centers",
                    "Handles conflict resolution proactively",
                    "Provides weather deviations and reroutes as needed",
                    "Maintains situational awareness of all aircraft in sector",
                    "Manages crossing traffic and altitude changes",
                    "Ensures smooth transition between sectors and FIR boundaries",
                    "Uses correct phraseology and maintains professional communication"
                ])
            ]
        )
    ]

    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<ExamSection>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for (index, seed) in sections.enumerated() {
            let examSection = ExamSection(
                level: seed.level,
                displayName: seed.displayName,
                passingThreshold: seed.passingThreshold,
                orderIndex: index
            )
            context.insert(examSection)

            for (groupIndex, group) in seed.groups.enumerated() {
                let criterionGroup = CriterionGroup(
                    label: group.label,
                    orderIndex: groupIndex,
                    criteria: group.criteria
                )
                context.insert(criterionGroup)
                examSection.groups.append(criterionGroup)
            }
        }

        try? context.save()
    }

    static func criterionScores(for level: RatingLevel, from context: ModelContext) -> [CriterionScore] {
        let allSections = (try? context.fetch(FetchDescriptor<ExamSection>())) ?? []
        guard let examSection = allSections.first(where: { $0.level == level }) else { return [] }

        var scores: [CriterionScore] = []
        let sortedGroups = examSection.groups.sorted { $0.orderIndex < $1.orderIndex }

        var orderIndex = 0
        for group in sortedGroups {
            for criterion in group.criteria {
                scores.append(CriterionScore(
                    criterionText: criterion,
                    groupLabel: group.label,
                    orderIndex: orderIndex,
                    ratingLevel: level
                ))
                orderIndex += 1
            }
        }
        return scores
    }
}
