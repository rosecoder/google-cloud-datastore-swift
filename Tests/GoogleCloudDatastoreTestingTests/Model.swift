import Foundation
import GoogleCloudDatastore

struct User: Entity, Equatable {
  struct Key: IndependentKey {
    static let kind = "TesttttUser"
    let id: ID
  }

  var key: Key
  let email: String

  enum CodingKeys: String, CodingKey {
    case key
    case email = "Email"
  }
}

struct UserWithAge: Entity, Equatable {
  struct Key: IndependentKey {
    static let kind = "TesttttUserWithAge"
    let id: ID
  }

  var key: Key
  let email: String
  let age: Int

  enum CodingKeys: String, CodingKey {
    case key
    case email = "Email"
    case age = "Age"
  }
}

struct UserWithAgeAndName: Entity, Equatable {
  struct Key: IndependentKey {
    static let kind = "TesttttUserWithAgeAndName"
    let id: ID
  }

  var key: Key
  let name: String
  let email: String
  let age: Int

  enum CodingKeys: String, CodingKey {
    case key
    case name = "Name"
    case email = "Email"
    case age = "Age"
  }
}

struct UserWithBinaryData: Entity, Equatable {
  struct Key: IndependentKey {
    static let kind = "TesttttUserWithBinaryData"
    let id: ID
  }

  var key: Key
  let email: String
  let binaryData: Data

  enum CodingKeys: String, CodingKey {
    case key
    case email = "Email"
    case binaryData = "BinaryData"
  }
}
