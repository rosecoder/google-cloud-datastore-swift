import Testing
import Foundation
@testable import GoogleCloudDatastore

@Suite struct EntityCodingTests {

    private let encoder = EntityEncoder()
    private let decoder = EntityDecoder()

    // MARK: - Coding Property Configuration

    @Test func codingPropertyConfiguration() throws {
        let source = entity(key: .incomplete)

        let raw = try encoder.encode(source)

        let stringProperty = try #require(raw.properties["String"])
        let intProperty = try #require(raw.properties["Int"])

        #expect(stringProperty.excludeFromIndexes)
        #expect(intProperty.excludeFromIndexes == false)
        assert(raw: raw, matching: source)
    }

    // MARK: - Coding Properties

    @Test func withIncompleteKey() throws {
        let source = entity(key: .incomplete)

        let raw = try encoder.encode(source)
        #expect(raw.key.partitionID.namespaceID == "")
        #expect(raw.key.path.count == 1)
        #expect(raw.key.path.first?.kind == AllPropertyTypeEntity.Key.kind)
        #expect(raw.key.path.first?.idType == nil)
        assert(raw: raw, matching: source)

        let entity = try decoder.decode(AllPropertyTypeEntity.self, from: raw)
        #expect(entity == source)
    }

    @Test func withIDKey() throws {
        let source = entity(key: .uniq(1))

        let raw = try encoder.encode(source)
        #expect(raw.key.partitionID.namespaceID == "")
        #expect(raw.key.path.count == 1)
        #expect(raw.key.path.first?.kind == AllPropertyTypeEntity.Key.kind)
        #expect(raw.key.path.first?.id == 1)
        assert(raw: raw, matching: source)

        let entity = try decoder.decode(AllPropertyTypeEntity.self, from: raw)
        #expect(entity == source)
    }

    @Test func withNamedKey() throws {
        let source = entity(key: .named("abc"))

        let raw = try encoder.encode(source)
        #expect(raw.key.partitionID.namespaceID == "")
        #expect(raw.key.path.count == 1)
        #expect(raw.key.path.first?.kind == AllPropertyTypeEntity.Key.kind)
        #expect(raw.key.path.first?.name == "abc")
        assert(raw: raw, matching: source)

        let entity = try decoder.decode(AllPropertyTypeEntity.self, from: raw)
        #expect(entity == source)
    }

    // MARK: - Coding Keys

    @Test func withIndependentKey() throws {
        let source = IndependentKeyEntity(key: .named("c"))

        let raw = try encoder.encode(source)
        #expect(raw.key.partitionID.namespaceID == "")
        #expect(raw.key.path.count == 1)
        #expect(raw.key.path.first?.kind == IndependentKeyEntity.Key.kind)
        #expect(raw.key.path.first?.name == "c")

        let entity = try decoder.decode(IndependentKeyEntity.self, from: raw)
        #expect(entity == source)
    }

    @Test func withIndependentNamespaceableKey() throws {
        let source = IndependentNamespaceableKeyEntity(key: .named("c", namespace: .test1))

        let raw = try encoder.encode(source)
        #expect(raw.key.partitionID.namespaceID == "test1")
        #expect(raw.key.path.count == 1)
        #expect(raw.key.path.first?.kind == IndependentNamespaceableKeyEntity.Key.kind)
        #expect(raw.key.path.first?.name == "c")

        let entity = try decoder.decode(IndependentNamespaceableKeyEntity.self, from: raw)
        #expect(entity == source)
    }

    @Test func withParentableKey() throws {
        let source = ParentableKeyEntity(key: .named("c", parent: .named("p")))

        let raw = try encoder.encode(source)
        #expect(raw.key.partitionID.namespaceID == "")
        #expect(raw.key.path.count == 2)
        #expect(raw.key.path.first?.kind == ParentableKeyEntity.Key.Parent.kind)
        #expect(raw.key.path.first?.name == "p")
        #expect(raw.key.path.last?.kind == ParentableKeyEntity.Key.kind)
        #expect(raw.key.path.last?.name == "c")

        let entity = try decoder.decode(ParentableKeyEntity.self, from: raw)
        #expect(entity == source)
    }

    @Test func withParentableNamespaceableKey() throws {
        let source = ParentableNamespaceableKeyEntity(key: .named("c", parent: .named("p", namespace: .test1), namespace: .test1))

        let raw = try encoder.encode(source)
        #expect(raw.key.partitionID.namespaceID == "test1")
        #expect(raw.key.path.count == 2)
        #expect(raw.key.path.first?.kind == ParentableNamespaceableKeyEntity.Key.Parent.kind)
        #expect(raw.key.path.first?.name == "p")
        #expect(raw.key.path.last?.kind == ParentableNamespaceableKeyEntity.Key.kind)
        #expect(raw.key.path.last?.name == "c")

        let entity = try decoder.decode(ParentableNamespaceableKeyEntity.self, from: raw)
        #expect(entity == source)
    }

    // MARK: -

    private func entity(key: AllPropertyTypeEntity.Key) -> AllPropertyTypeEntity {
        AllPropertyTypeEntity(
            key: key,

            string: "test",

            int: 5,
            int8: 6,
            int16: 7,
            int32: 8,
            int64: 9,
            uInt: 10,
            uInt8: 11,
            uInt16: 12,
            uInt32: 13,
            uInt64: 14,

            float: 0.5,
            double: 1.32,

            date: Date(timeIntervalSince1970: 1),

            data: Data([1, 2, 3]),

            nilValue: nil,

            entity: User(key: .incomplete, email: "testing"),
            array: ["a", "b", "c", "z"],
            dictionary: ["a": 1, "b": 2, "c": 3]
        )
    }

    private func assert(raw: Google_Datastore_V1_Entity, matching entity: AllPropertyTypeEntity, file: StaticString = #file, line: UInt = #line) {
        #expect(raw.properties["String"]?.stringValue == entity.string)
        #expect(raw.properties["Int"]?.integerValue == Int64(entity.int))
        #expect(raw.properties["Int8"]?.integerValue == Int64(entity.int8))
        #expect(raw.properties["Int16"]?.integerValue == Int64(entity.int16))
        #expect(raw.properties["Int32"]?.integerValue == Int64(entity.int32))
        #expect(raw.properties["Int64"]?.integerValue == Int64(entity.int64))
        #expect(raw.properties["UInt"]?.integerValue == Int64(entity.uInt))
        #expect(raw.properties["UInt8"]?.integerValue == Int64(entity.uInt8))
        #expect(raw.properties["UInt16"]?.integerValue == Int64(entity.uInt16))
        #expect(raw.properties["UInt32"]?.integerValue == Int64(entity.uInt32))
        #expect(raw.properties["UInt64"]?.integerValue == Int64(entity.uInt64))
        #expect(raw.properties["Float"]?.doubleValue == Double(entity.float))
        #expect(raw.properties["Double"]?.doubleValue == entity.double)
        #expect(raw.properties["Date"]?.timestampValue.date == entity.date)
        #expect(raw.properties["Data"]?.blobValue == entity.data)
        #expect(raw.properties["Nil"]?.valueType == .nullValue(.nullValue))
        #expect(raw.properties["Entity"]?.entityValue.properties["Email"]?.valueType == .stringValue("testing"))
        #expect(raw.properties["Array"]?.arrayValue.values.first?.valueType == .stringValue("a"))
        #expect(raw.properties["Array"]?.arrayValue.values.last?.valueType == .stringValue("z"))
        #expect(raw.properties["Dictionary"]?.entityValue.properties["a"]?.valueType == .integerValue(1))
        #expect(raw.properties["Dictionary"]?.entityValue.properties["b"]?.valueType == .integerValue(2))
        #expect(raw.properties["Dictionary"]?.entityValue.properties["c"]?.valueType == .integerValue(3))
    }
}
