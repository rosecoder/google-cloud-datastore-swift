import Testing
import Foundation
import GoogleCloudDatastore

@Suite(.enabled(if: ProcessInfo.processInfo.environment["DATASTORE_EMULATOR_HOST"] != nil))
class GetTests {

    let existingUniqKey: User.Key = .uniq(35611)
    let existingNamedKey: User.Key = .named("zw48ad")
    let datastore: Datastore
    let runTask: Task<Void, Error>

    init() async throws {
        let datastore = try Datastore(projectID: "test-get-tests-\(UUID().uuidString.lowercased())")
        self.datastore = datastore
        self.runTask = Task { try await datastore.run() }

        var users: [User] = [
            User(key: existingUniqKey, email: "tester-uniq"),
            User(key: existingNamedKey, email: "tester-named")
        ]
        try await datastore.put(entities: &users)
    }

    deinit {
        runTask.cancel()
    }

    // MARK: - Get

    @Test func getExistingWithUniqID() async throws {

        let user = try #require(try await datastore.getEntity(User.self, key: existingUniqKey))
        #expect(user.email == "tester-uniq")

        runTask.cancel()
        try await runTask.value
    }

    @Test func getExistingWithNamedID() async throws {
        let user = try #require(try await datastore.getEntity(User.self, key: existingNamedKey))
        #expect(user.email == "tester-named")
    }

    @Test func notFound() async throws {
        let userMaybe = try await datastore.getEntity(User.self, key: .uniq(1294578))
        #expect(userMaybe == nil)
    }

    // MARK: - Contains

    @Test func containsExisting() async throws {
        let exists = try await datastore.containsEntity(key: existingUniqKey)
        #expect(exists)
    }

    @Test func containsNotExisting() async throws {
        let exists = try await datastore.containsEntity(key: User.Key.uniq(15209152))
        #expect(exists == false)
    }
}
