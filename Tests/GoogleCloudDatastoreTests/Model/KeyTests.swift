import Testing
import Foundation
import GoogleCloudDatastore

@Suite struct KeyTests {

    // MARK: - Codable

    private func assertCodable<T: AnyKey>(source: T) throws {
        let raw = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(T.self, from: raw)
        #expect(decoded == source)
    }

    @Test func coding_IndependentKey() throws {
        try assertCodable(source: IndependentKeyEntity.Key.named("c"))
    }

    @Test func coding_IndependentNamespaceableKey() throws {
        try assertCodable(source: IndependentNamespaceableKeyEntity.Key.named("c", namespace: .test1))
    }

    @Test func coding_ParentableKey() throws {
        try assertCodable(source: ParentableKeyEntity.Key.named("c", parent: .named("p")))
    }

    @Test func coding_ParentableNamespaceableKey() throws {
        try assertCodable(source: ParentableNamespaceableKeyEntity.Key.named("c", parent: .named("p", namespace: .test1), namespace: .test1))
    }

    // MARK: - CustomDebugStringConvertible

    @Test func description_IndependentKey() throws {
        #expect(IndependentKeyEntity.Key.named("c").debugDescription == ".Testttt-IndependentKeyEntity:\"c\"")
    }

    @Test func description_IndependentNamespaceableKey() throws {
        #expect(IndependentNamespaceableKeyEntity.Key.named("c", namespace: .test1).debugDescription == "test1.Testttt-IndependentNamespaceableKeyEntity:\"c\"")
    }

    @Test func description_ParentableKey() throws {
        #expect(ParentableKeyEntity.Key.named("c", parent: .named("p")).debugDescription == ".Testttt-IndependentKeyEntity:\"p\".Testttt-ParentableKeyEntity:\"c\"")
    }

    @Test func description_ParentableNamespaceableKey() throws {
        #expect(ParentableNamespaceableKeyEntity.Key.named("c", parent: .named("p", namespace: .test1), namespace: .test1).debugDescription == "test1.Testttt-IndependentNamespaceableKeyEntity:\"p\".Testttt-ParentableNamespaceableKeyEntity:\"c\"")
    }
}
