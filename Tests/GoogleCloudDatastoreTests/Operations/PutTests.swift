import Testing
import Foundation
import GoogleCloudDatastore

@Suite(.enabled(if: ProcessInfo.processInfo.environment["DATASTORE_EMULATOR_HOST"] != nil))
struct PutTests {

    let datastore: Datastore
    let runTask: Task<Void, Error>

    init() throws {
        let datastore = try Datastore(projectID: "test-get-tests-\(UUID().uuidString.lowercased())")
        self.datastore = datastore
        self.runTask = Task { try await datastore.run() }
    }

    @Test func putNewWithIncompleteKey() async throws {
        var user = User(key: .incomplete, email: "testing")
        try await datastore.put(entity: &user)

        switch user.key.id {
        case .uniq(let id):
            #expect(id > 0)
        default:
            Issue.record("Key is not set: \(user.key)")
        }

        let putUser = try #require(try await datastore.getEntity(User.self, key: user.key))
        #expect(putUser == user)
    }

    @Test func putNewWithUniqKey() async throws {
        let key = User.Key.uniq(235798)

        let exists = try await datastore.containsEntity(key: key)
        #expect(exists == false, "Precondition: User should not exist before test starts.")

        var user = User(key: key, email: "testing")
        try await datastore.put(entity: &user)
        #expect(user.key == key)

        let putUser = try #require(try await datastore.getEntity(User.self, key: user.key))
        #expect(putUser == user)
    }

    @Test func putNewWithNamedKey() async throws {
        let key = User.Key.named("zg4bi")

        let exists = try await datastore.containsEntity(key: key)
        #expect(exists == false, "Precondition: User should not exist before test starts.")

        var user = User(key: key, email: "testing")
        try await datastore.put(entity: &user)
        #expect(user.key == key)

        let putUser = try #require(try await datastore.getEntity(User.self, key: user.key))
        #expect(putUser == user)
    }
}
