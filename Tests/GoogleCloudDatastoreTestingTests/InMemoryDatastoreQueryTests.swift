import Foundation
import GoogleCloudDatastore
import GoogleCloudDatastoreTesting
import Testing

struct InMemoryDatastoreQueryTests {

  let datastore = InMemoryDatastore()

  @Test func shouldReturnEmptyArrayForEmptyDatastore() async throws {
    let query = Query(User.self)
    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    #expect(results.isEmpty)
  }

  @Test func shouldFilterEntitiesByEqualCondition() async throws {
    // Setup test data
    var user1 = User(key: .named("user1"), email: "user1@example.com")
    var user2 = User(key: .named("user2"), email: "user2@example.com")
    var user3 = User(key: .named("user3"), email: "user1@example.com")  // Same email as user1

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)

    // Query for users with email equal to user1@example.com
    var query = Query(User.self)
    query.filter(by: .email, where: .equals("user1@example.com"))

    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    #expect(results.count == 2)
    #expect(results.contains(where: { $0.key.id == .named("user1") }))
    #expect(results.contains(where: { $0.key.id == .named("user3") }))
  }

  @Test func shouldFilterEntitiesByGreaterThanCondition() async throws {
    // Setup test data with numeric values
    var user1 = UserWithAge(key: .named("user1"), email: "user1@example.com", age: 25)
    var user2 = UserWithAge(key: .named("user2"), email: "user2@example.com", age: 30)
    var user3 = UserWithAge(key: .named("user3"), email: "user3@example.com", age: 20)

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)

    // Query for users with age > 25
    var query = Query(UserWithAge.self)
    query.filter(by: .age, where: .greaterThan(25))

    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    #expect(results.map(\.key.id) == [.named("user2")])
  }

  @Test func shouldFilterEntitiesByGreaterThanOrEqualCondition() async throws {
    // Setup test data with numeric values
    var user1 = UserWithAge(key: .named("user1"), email: "user1@example.com", age: 25)
    var user2 = UserWithAge(key: .named("user2"), email: "user2@example.com", age: 30)
    var user3 = UserWithAge(key: .named("user3"), email: "user3@example.com", age: 20)

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)

    // Query for users with age >= 25
    var query = Query(UserWithAge.self)
    query.filter(by: .age, where: .greaterThanOrEqual(25))

    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    #expect(Set(results.map(\.key.id)) == [.named("user1"), .named("user2")])
  }

  @Test func shouldFilterEntitiesByLessThanCondition() async throws {
    // Setup test data with numeric values
    var user1 = UserWithAge(key: .named("user1"), email: "user1@example.com", age: 25)
    var user2 = UserWithAge(key: .named("user2"), email: "user2@example.com", age: 30)
    var user3 = UserWithAge(key: .named("user3"), email: "user3@example.com", age: 20)

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)

    // Query for users with age < 25
    var query = Query(UserWithAge.self)
    query.filter(by: .age, where: .lessThan(25))

    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    #expect(results.count >= 1)
    #expect(results.contains(where: { $0.age < 25 }))
  }

  @Test func shouldFilterEntitiesByLessThanOrEqualCondition() async throws {
    // Setup test data with numeric values
    var user1 = UserWithAge(key: .named("user1"), email: "user1@example.com", age: 25)
    var user2 = UserWithAge(key: .named("user2"), email: "user2@example.com", age: 30)
    var user3 = UserWithAge(key: .named("user3"), email: "user3@example.com", age: 20)

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)

    // Query for users with age <= 25
    var query = Query(UserWithAge.self)
    query.filter(by: .age, where: .lessThanOrEqual(25))

    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    #expect(results.count >= 1)
    #expect(results.contains(where: { $0.age <= 25 }))
  }

  @Test func shouldOrderEntitiesAscending() async throws {
    // Setup test data with numeric values
    var user1 = UserWithAge(key: .named("user1"), email: "user1@example.com", age: 25)
    var user2 = UserWithAge(key: .named("user2"), email: "user2@example.com", age: 30)
    var user3 = UserWithAge(key: .named("user3"), email: "user3@example.com", age: 20)

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)

    // Query for users ordered by age ascending
    var query = Query(UserWithAge.self)
    query.order(by: .age, direction: .ascending)

    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    #expect(results.count == 3)

    // Check that the results are in ascending order
    if results.count >= 2 {
      for i in 0..<(results.count - 1) {
        #expect(results[i].age <= results[i + 1].age)
      }
    }
  }

  @Test func shouldOrderEntitiesDescending() async throws {
    // Setup test data with numeric values
    var user1 = UserWithAge(key: .named("user1"), email: "user1@example.com", age: 25)
    var user2 = UserWithAge(key: .named("user2"), email: "user2@example.com", age: 30)
    var user3 = UserWithAge(key: .named("user3"), email: "user3@example.com", age: 20)

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)

    // Query for users ordered by age descending
    var query = Query(UserWithAge.self)
    query.order(by: .age, direction: .descending)

    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    #expect(results.count == 3)

    // Check that the results are in descending order
    if results.count >= 2 {
      for i in 0..<(results.count - 1) {
        #expect(results[i].age >= results[i + 1].age)
      }
    }
  }

  @Test func shouldLimitResults() async throws {
    // Setup test data
    var user1 = User(key: .named("user1"), email: "user1@example.com")
    var user2 = User(key: .named("user2"), email: "user2@example.com")
    var user3 = User(key: .named("user3"), email: "user3@example.com")

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)

    // Query with limit
    let query = Query(User.self, limit: 2)

    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    #expect(results.count == 2)
  }

  @Test func shouldHandlePagination() async throws {
    // Setup test data - create 5 users to ensure we have enough for pagination
    var user1 = User(key: .named("user1"), email: "user1@example.com")
    var user2 = User(key: .named("user2"), email: "user2@example.com")
    var user3 = User(key: .named("user3"), email: "user3@example.com")
    var user4 = User(key: .named("user4"), email: "user4@example.com")
    var user5 = User(key: .named("user5"), email: "user5@example.com")

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)
    try await datastore.put(entity: &user4)
    try await datastore.put(entity: &user5)

    // Get total count first
    let allQuery = Query(User.self)
    let allResults = try await datastore.getEntities(
      query: allQuery, file: #file, function: #function, line: #line)
    let totalCount = allResults.count

    // Skip test if we don't have enough entities
    guard totalCount >= 3 else {
      Issue.record("Not enough entities for pagination test")
      return
    }

    // Query with pagination - page size 2
    let pageSize: Int32 = 2
    let query = Query(User.self, limit: pageSize)

    // First page
    var cursor: Cursor?
    let firstPage = try await datastore.getEntities(
      query: query, cursor: &cursor, file: #file, function: #function, line: #line)

    #expect(firstPage.count <= Int(pageSize))

    // Get second page if we have a cursor
    if cursor != nil && firstPage.count == pageSize {
      let secondPage = try await datastore.getEntities(
        query: query, cursor: &cursor, file: #file, function: #function, line: #line)

      // Verify we got some results (could be up to pageSize)
      #expect(secondPage.count >= 0)
      #expect(secondPage.count <= Int(pageSize))

      // Verify first and second pages have different entities
      let firstPageIds = Set(firstPage.map { $0.key.id.description })
      let secondPageIds = Set(secondPage.map { $0.key.id.description })
      let intersection = firstPageIds.intersection(secondPageIds)
      #expect(intersection.isEmpty, "First and second pages should have different entities")
    }
  }

  @Test func shouldPageThroughAllEntitiesUntilCursorIsNil() async throws {
    for index in 1...5 {
      var user = User(key: .named("user\(index)"), email: "user\(index)@example.com")
      try await datastore.put(entity: &user)
    }

    let query = Query(User.self, limit: 2)
    var cursor: Cursor?
    var pageSizes: [Int] = []
    var ids: [ID] = []
    repeat {
      let page = try await datastore.getEntities(
        query: query, cursor: &cursor, file: #file, function: #function, line: #line)
      pageSizes.append(page.count)
      ids += page.map(\.key.id)
    } while cursor != nil && pageSizes.count < 10

    #expect(pageSizes == [2, 2, 1])
    #expect(Set(ids).count == 5)
  }

  @Test func shouldReturnKeysInsteadOfEntities() async throws {
    // Setup test data
    var user1 = User(key: .named("user1"), email: "user1@example.com")
    var user2 = User(key: .named("user2"), email: "user2@example.com")

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)

    // Get keys
    let query = Query(User.self)
    let keys = try await datastore.getKeys(
      query: query, file: #file, function: #function, line: #line)

    #expect(keys.count == 2)
    #expect(keys.contains(where: { $0.id == .named("user1") }))
    #expect(keys.contains(where: { $0.id == .named("user2") }))
  }

  @Test func shouldCombineFiltersAndOrders() async throws {
    // Setup test data
    var user1 = UserWithAgeAndName(
      key: .named("user1"), name: "Alice", email: "alice@example.com", age: 25)
    var user2 = UserWithAgeAndName(
      key: .named("user2"), name: "Bob", email: "bob@example.com", age: 30)
    var user3 = UserWithAgeAndName(
      key: .named("user3"), name: "Charlie", email: "charlie@example.com", age: 20)
    var user4 = UserWithAgeAndName(
      key: .named("user4"), name: "David", email: "david@example.com", age: 25)

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)
    try await datastore.put(entity: &user4)

    // Query with filter and order
    var query = Query(UserWithAgeAndName.self)
    query.filter(by: .age, where: .greaterThanOrEqual(25))
    query.order(by: .name, direction: .ascending)

    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    // Check that all results have age >= 25
    #expect(results.allSatisfy { $0.age >= 25 })

    // Check that results are in ascending order by name
    if results.count >= 2 {
      for i in 0..<(results.count - 1) {
        #expect(results[i].name <= results[i + 1].name)
      }
    }
  }

  @Test func shouldFilterEntitiesByBinaryDataEqualCondition() async throws {
    // Setup test data with binary data
    let binaryData1 = "test data 1".data(using: .utf8)!
    let binaryData2 = "test data 2".data(using: .utf8)!

    var user1 = UserWithBinaryData(
      key: .named("user1"), email: "user1@example.com", binaryData: binaryData1)
    var user2 = UserWithBinaryData(
      key: .named("user2"), email: "user2@example.com", binaryData: binaryData2)
    var user3 = UserWithBinaryData(
      key: .named("user3"), email: "user3@example.com", binaryData: binaryData1)  // Same binary data as user1

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)

    // Query for users with binary data equal to binaryData1
    var query = Query(UserWithBinaryData.self)
    query.filter(by: .binaryData, where: .equals(binaryData1))

    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    // This will fail because of the base64 encoding issue
    #expect(results.count == 2)
    #expect(results.contains(where: { $0.key.id == .named("user1") }))
    #expect(results.contains(where: { $0.key.id == .named("user3") }))
  }

  @Test func shouldFilterEntitiesByBinaryDataInequalityCondition() async throws {
    // Setup test data with binary data of different sizes
    let smallData = "small".data(using: .utf8)!
    let mediumData = "medium data".data(using: .utf8)!
    let largeData = "large data content".data(using: .utf8)!

    var user1 = UserWithBinaryData(
      key: .named("user1"), email: "user1@example.com", binaryData: smallData)
    var user2 = UserWithBinaryData(
      key: .named("user2"), email: "user2@example.com", binaryData: mediumData)
    var user3 = UserWithBinaryData(
      key: .named("user3"), email: "user3@example.com", binaryData: largeData)

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)

    // In lexicographical order: largeData < mediumData < smallData
    // (because 'l' < 'm' < 's' in ASCII)

    // Query for users with binary data greater than largeData
    var query = Query(UserWithBinaryData.self)
    query.filter(by: .binaryData, where: .greaterThan(largeData))

    let results = try await datastore.getEntities(
      query: query, file: #file, function: #function, line: #line)

    #expect(Set(results.map(\.key.id)) == [.named("user1"), .named("user2")])

    // Query for users with binary data less than smallData
    var query2 = Query(UserWithBinaryData.self)
    query2.filter(by: .binaryData, where: .lessThan(smallData))

    let results2 = try await datastore.getEntities(
      query: query2, file: #file, function: #function, line: #line)

    #expect(results2.count == 2)
    #expect(results2.contains(where: { $0.key.id == .named("user2") }))
    #expect(results2.contains(where: { $0.key.id == .named("user3") }))
  }

  @Test func shouldFilterEntitiesByDate() async throws {
    let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    var user1 = UserWithLastSeen(
      key: .named("user1"), email: "user1@example.com", lastSeen: now.addingTimeInterval(-60))
    var user2 = UserWithLastSeen(key: .named("user2"), email: "user2@example.com", lastSeen: now)
    var user3 = UserWithLastSeen(
      key: .named("user3"), email: "user3@example.com", lastSeen: now.addingTimeInterval(60))

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)
    try await datastore.put(entity: &user3)

    var lessThanOrEqualQuery = Query(UserWithLastSeen.self)
    lessThanOrEqualQuery.filter(by: .lastSeen, where: .lessThanOrEqual(now))
    let lessThanOrEqualResults = try await datastore.getEntities(
      query: lessThanOrEqualQuery, file: #file, function: #function, line: #line)
    #expect(Set(lessThanOrEqualResults.map(\.key.id)) == [.named("user1"), .named("user2")])

    var lessThanQuery = Query(UserWithLastSeen.self)
    lessThanQuery.filter(by: .lastSeen, where: .lessThan(now))
    let lessThanResults = try await datastore.getEntities(
      query: lessThanQuery, file: #file, function: #function, line: #line)
    #expect(lessThanResults.map(\.key.id) == [.named("user1")])

    var greaterThanOrEqualQuery = Query(UserWithLastSeen.self)
    greaterThanOrEqualQuery.filter(by: .lastSeen, where: .greaterThanOrEqual(now))
    let greaterThanOrEqualResults = try await datastore.getEntities(
      query: greaterThanOrEqualQuery, file: #file, function: #function, line: #line)
    #expect(Set(greaterThanOrEqualResults.map(\.key.id)) == [.named("user2"), .named("user3")])

    var greaterThanQuery = Query(UserWithLastSeen.self)
    greaterThanQuery.filter(by: .lastSeen, where: .greaterThan(now))
    let greaterThanResults = try await datastore.getEntities(
      query: greaterThanQuery, file: #file, function: #function, line: #line)
    #expect(greaterThanResults.map(\.key.id) == [.named("user3")])

    var equalQuery = Query(UserWithLastSeen.self)
    equalQuery.filter(by: .lastSeen, where: .equals(now))
    let equalResults = try await datastore.getEntities(
      query: equalQuery, file: #file, function: #function, line: #line)
    #expect(equalResults.map(\.key.id) == [.named("user2")])
  }

  @Test func shouldOnlyReturnEntitiesInQueryNamespace() async throws {
    let namespaceA = Namespace(rawValue: "a")
    let namespaceB = Namespace(rawValue: "b")
    var user1 = NamespacedUser(
      key: .named("user1", namespace: namespaceA), email: "user1@example.com")
    var user2 = NamespacedUser(
      key: .named("user2", namespace: namespaceB), email: "user2@example.com")

    try await datastore.put(entity: &user1)
    try await datastore.put(entity: &user2)

    let results = try await datastore.getEntities(
      query: Query(NamespacedUser.self, namespace: namespaceA),
      file: #file, function: #function, line: #line)

    #expect(results == [user1])
  }

  @Test func shouldOnlyReturnEntitiesOfQueryKind() async throws {
    var user = User(key: .named("user1"), email: "user1@example.com")
    var userWithAge = UserWithAge(key: .named("user2"), email: "user2@example.com", age: 30)

    try await datastore.put(entity: &user)
    try await datastore.put(entity: &userWithAge)

    let results = try await datastore.getEntities(
      query: Query(User.self), file: #file, function: #function, line: #line)

    #expect(results == [user])
  }
}
