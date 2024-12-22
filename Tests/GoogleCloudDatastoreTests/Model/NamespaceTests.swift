import Testing
import Foundation
@testable import GoogleCloudDatastore

@Suite struct NamespaceTests {

    let aNamespace = Namespace(rawValue: "testing")

    // MARK: - Codable

    @Test func codable() throws {
        let data = try JSONEncoder().encode(aNamespace)

        let decoded = try JSONDecoder().decode(Namespace.self, from: data)
        #expect(aNamespace == decoded)
    }

    // MARK: - CustomStringConvertible

    @Test func customStringConvertible() {
        #expect(aNamespace.description == "testing")
    }

    // MARK: - CustomDebugStringConvertible

    @Test func customDebugStringConvertible() {
        #expect(aNamespace.debugDescription == "testing")
    }
}
