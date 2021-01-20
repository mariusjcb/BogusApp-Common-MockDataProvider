import Foundation
import BogusApp_Common_Models

public class MockTarget: Codable {
    public let name: String
    public let channels: [String]
    
    public func convert(with fees: [String: [Fee]]) -> TargetSpecific {
        let channels = self.channels.map { Channel(id: UUID(), name: $0, fees: fees[$0]!) }
        return TargetSpecific(id: UUID(), title: name, channels: channels)
    }
}

public class MockFee: Codable {
    public let price: Double
    public let benefits: [String]
    
    public func convert() -> Fee {
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
        
        return Fee(id: UUID(), price: price, benefits: benefits, type: .monthly)
    }
}

public class MockData: Codable {
    public let targets: [MockTarget]
    public let fees: [String: [MockFee]]
    
    private static var SPECS_JSON_URL: String {
        return ProcessInfo.processInfo.environment["SPECS_JSON"] ?? "https://jsonkeeper.com/b/SOLH"
    }
    
    public static func fetch() -> MockData? {
        let data = try! Data(contentsOf: URL(string: SPECS_JSON_URL)!)
        return try? JSONDecoder().decode(MockData.self, from: data)
    }
    
    public func convert() -> [TargetSpecific] {
        let fees = Dictionary(uniqueKeysWithValues: self.fees.map { key, value in (key, value.map { $0.convert() }) })
        return targets.map { $0.convert(with: fees) }
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
