import Testing
import Foundation
@testable import GoogleCloudDatastore

@Suite struct IDTests {

    // MARK: - Codable

    @Test func codableUniq() throws {
        let encodedID = ID.uniq(123)
        let data = try JSONEncoder().encode(encodedID)

        let decodedID = try JSONDecoder().decode(ID.self, from: data)
        #expect(encodedID == decodedID)
    }

    @Test func codableNamed() throws {
        let encodedID = ID.named("123")
        let data = try JSONEncoder().encode(encodedID)

        let decodedID = try JSONDecoder().decode(ID.self, from: data)
        #expect(encodedID == decodedID)
    }

    @Test func codableIncomplete() throws {
        let encodedID = ID.incomplete
        let data = try JSONEncoder().encode(encodedID)

        let decodedID = try JSONDecoder().decode(ID.self, from: data)
        #expect(encodedID == decodedID)
    }

    // MARK: - CustomStringConvertible

    @Test func customStringConvertible() {
        #expect(ID.uniq(123).description == "123")
        #expect(ID.named("123").description == "123")
        #expect(ID.incomplete.description == "")
    }

    // MARK: - CustomDebugStringConvertible

    @Test func customDebugStringConvertible() {
        #expect(ID.uniq(123).debugDescription == "123")
        #expect(ID.named("123").debugDescription == "\"123\"")
        #expect(ID.incomplete.debugDescription == "<incomplete>")
    }
}
