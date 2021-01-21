import Foundation
import BogusApp_Common_Models

public class MockTarget: Codable {
    public let name: String
    public let channels: [String]
    
    public func convert(with plans: [String: [Plan]]) -> TargetSpecific {
        let channels = self.channels.map { Channel(id: UUID(), name: $0, plans: plans[$0]!) }
        return TargetSpecific(id: UUID(), title: name, channels: channels)
    }
}

public class MockPlan: Codable {
    public let price: Double
    public let benefits: [String]
    
    public func convert() -> Plan {
        let benefits: [Benefit] = self.benefits.map { str in
            if let match = str.match("[\\d.]+-[\\d.]+") {
                let matches = match.split(separator: "-").map { Int(String($0))! }
                return Benefit(id: UUID(), name: str, type: .range(matches.first!...matches.last!))
            } else if let match = str.match("[\\d.]+") {
                return Benefit(id: UUID(), name: str, type: .value(Int(match)!))
            } else {
                return Benefit(id: UUID(), name: str, type: .text)
            }
        }
        
        return Plan(id: UUID(), price: price, benefits: benefits, type: .monthly)
    }
}

public class MockData: Codable {
    public let targets: [MockTarget]
    public let plans: [String: [MockPlan]]
    
    private static var SPECS_JSON_URL: String {
        return ProcessInfo.processInfo.environment["SPECS_JSON"] ?? "https://api.npoint.io/f7abcb83c8b4aabcb22d"
    }
    
    public static func fetch() -> MockData? {
        let data = try! Data(contentsOf: URL(string: SPECS_JSON_URL)!)
        return try? JSONDecoder().decode(MockData.self, from: data)
    }
    
    public func convertAllChannelsOnly() -> [Channel] {
        return MockData.fetch()!.convert().map { $0.channels }.reduce([], +)
    }
    
    public func convertAllPlansOnly() -> [Plan] {
        return convertAllChannelsOnly().map { $0.plans }.reduce([], +)
    }
    
    public func convertAllBenefitsOnly() -> [Benefit] {
        return convertAllPlansOnly().map { $0.benefits }.reduce([], +)
    }
    
    public func convert() -> [TargetSpecific] {
        let plans = Dictionary(uniqueKeysWithValues: self.plans.map { key, value in (key, value.map { $0.convert() }) })
        return targets.map { $0.convert(with: plans) }
    }
}

extension String {
    func match(_ regex: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.map { String(self[Range($0.range, in: self)!]) }.first
        } catch {
            return nil
        }
    }
}
