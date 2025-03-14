import Foundation
import GoogleCloudDatastore

extension InMemoryDatastore {

  // Note: This implementation is a quick hack and super duper non-performant at all
  public func getEntities<Entity: _Entity>(
    query: Query<Entity>,
    cursor: inout Cursor?,
    file: String,
    function: String,
    line: UInt
  ) async throws -> [Entity] {
    let toSkip = cursor.flatMap { Int($0.stringValue) } ?? 0

    let entities = storage.values
      .compactMap { (data: Data) -> (Entity, [String: Any])? in
        guard let decoded = try? decoder.decode(Entity.self, from: data) else {
          return nil
        }
        return (decoded, try! JSONSerialization.jsonObject(with: data) as! [String: Any])
      }
      .filter { filter(properties: $0.1, filters: query.filters) }
      .sorted { compare(lhs: $0.1, rhs: $1.1, orders: query.orders) }
      .map { $0.0 }

    let result: [Entity] =
      if let limit = query.limit {
        Array(entities[toSkip..<min(entities.count, toSkip + Int(limit))])
      } else {
        Array(entities[toSkip...])
      }

    cursor = Cursor(stringValue: String(toSkip + result.count))

    return result
  }

  private nonisolated func filter(
    properties: [String: Any], filters: [Google_Datastore_V1_PropertyFilter]
  ) -> Bool {
    for filter in filters {
      let propertyName = filter.property.name
      guard let value = properties[propertyName] else {
        switch filter.op {
        case .equal:
          switch filter.value.valueType {
          case .nullValue, .none:
            continue
          default:
            return false
          }
        default:
          return false
        }
      }

      // Handle the case where value is a base64 encoded string but filter.value is a blob
      var processedValue = value
      if let stringValue = value as? String,
        case .blobValue = filter.value.valueType,
        let decodedData = Data(base64Encoded: stringValue)
      {
        processedValue = decodedData
      }

      switch filter.op {
      case .equal:
        let result = isEqual(lhs: processedValue, rhs: filter.value)
        if !result {
          return false
        }
      case .notEqual:
        let result = isEqual(lhs: processedValue, rhs: filter.value)
        if result {
          return false
        }
      case .lessThan:
        // For lessThan, we want to check if lhs < rhs
        // compare(lhs, rhs) returns true if lhs < rhs
        let comparisonResult = compare(
          lhs: processedValue, rhs: getValueFromValueType(filter.value.valueType))
        if comparisonResult != true {
          return false
        }
      case .lessThanOrEqual:
        // For lessThanOrEqual, we want to check if lhs <= rhs
        // compare(lhs, rhs) returns true if lhs < rhs, nil if lhs == rhs
        let comparisonResult = compare(
          lhs: processedValue, rhs: getValueFromValueType(filter.value.valueType))
        if comparisonResult != true && comparisonResult != nil {
          return false
        }
      case .greaterThan:
        // For greaterThan, we want to check if lhs > rhs
        // compare(lhs, rhs) returns false if lhs > rhs
        let comparisonResult = compare(
          lhs: processedValue, rhs: getValueFromValueType(filter.value.valueType))
        if comparisonResult != false && comparisonResult != nil {
          return false
        }
      case .greaterThanOrEqual:
        // For greaterThanOrEqual, we want to check if lhs >= rhs
        // compare(lhs, rhs) returns false if lhs > rhs, nil if lhs == rhs
        let comparisonResult = compare(
          lhs: processedValue, rhs: getValueFromValueType(filter.value.valueType))
        if comparisonResult == true {
          return false
        }
      case .hasAncestor:
        fatalError("Comparison not supported in InMemoryDatastore yet")
      case .in:
        fatalError("Comparison not supported in InMemoryDatastore yet")
      case .notIn:
        fatalError("Comparison not supported in InMemoryDatastore yet")
      case .unspecified, .UNRECOGNIZED:
        continue
      }
    }
    return true
  }

  private nonisolated func isEqual(lhs: Any, rhs: Google_Datastore_V1_Value) -> Bool {
    if let array = lhs as? [Any] {
      return array.contains(where: { isEqual(lhs: $0, rhs: rhs) })
    }

    switch rhs.valueType {
    case .nullValue, .none:
      return false
    case .booleanValue(let expected):
      return lhs as? Bool == expected
    case .integerValue(let expected):
      return lhs as? Int64 == expected
    case .doubleValue(let expected):
      return lhs as? Double == expected
    case .timestampValue(let expected):
      return (lhs as? Date)?.timeIntervalSinceReferenceDate
        == expected.timeIntervalSinceReferenceDate
    case .keyValue:
      fatalError("Comparison not supported in InMemoryDatastore yet")
    case .stringValue(let expected):
      return lhs as? String == expected
    case .blobValue(let expected):
      return lhs as? Data == expected
    case .geoPointValue:
      fatalError("Comparison not supported in InMemoryDatastore yet")
    case .entityValue:
      fatalError("Comparison not supported in InMemoryDatastore yet")
    case .arrayValue:
      fatalError("Comparison not supported in InMemoryDatastore yet")
    }
  }

  private nonisolated func isGreater(lhs: Any, rhs: Google_Datastore_V1_Value) -> Bool? {
    switch rhs.valueType {
    case .nullValue, .none:
      return true
    case .booleanValue(let expected):
      return compare(lhs: lhs, rhs: expected)
    case .integerValue(let expected):
      return compare(lhs: lhs, rhs: expected)
    case .doubleValue(let expected):
      return compare(lhs: lhs, rhs: expected)
    case .timestampValue(let expected):
      return compare(lhs: lhs, rhs: expected)
    case .keyValue:
      fatalError("Comparison not supported in InMemoryDatastore yet")
    case .stringValue(let expected):
      return compare(lhs: lhs, rhs: expected)
    case .blobValue(let expected):
      return compare(lhs: lhs, rhs: expected)
    case .geoPointValue:
      fatalError("Comparison not supported in InMemoryDatastore yet")
    case .entityValue:
      fatalError("Comparison not supported in InMemoryDatastore yet")
    case .arrayValue:
      fatalError("Comparison not supported in InMemoryDatastore yet")
    }
  }

  private nonisolated func compare(
    lhs: [String: Any], rhs: [String: Any], orders: [Google_Datastore_V1_PropertyOrder]
  ) -> Bool {
    for order in orders {
      let isAscending = order.direction == .ascending

      let propertyName = order.property.name
      let lhsProperty = lhs[propertyName]
      let rhsProperty = rhs[propertyName]
      if lhsProperty == nil && rhsProperty == nil {
        continue
      }
      guard let lhsProperty else {
        return !isAscending
      }
      guard let rhsProperty else {
        return !isAscending
      }
      if let result = compare(lhs: lhsProperty, rhs: rhsProperty) {
        return result == isAscending
      }
    }
    return true
  }

  private nonisolated func compare(lhs: Any, rhs: Any) -> Bool? {
    if let lhs = lhs as? String, let rhs = rhs as? String {
      if lhs == rhs { return nil }
      return lhs < rhs
    }
    if let lhs = lhs as? Int, let rhs = rhs as? Int {
      if lhs == rhs { return nil }
      return lhs < rhs
    }
    if let lhs = lhs as? Int64, let rhs = rhs as? Int64 {
      if lhs == rhs { return nil }
      return lhs < rhs
    }
    if let lhs = lhs as? Double, let rhs = rhs as? Double {
      if lhs == rhs { return nil }
      return lhs < rhs
    }
    if let lhs = lhs as? Date, let rhs = rhs as? Date {
      if lhs == rhs { return nil }
      return lhs < rhs
    }
    if let lhs = lhs as? Bool, let rhs = rhs as? Bool {
      if lhs == rhs { return nil }
      return lhs
    }
    if let lhs = lhs as? Data, let rhs = rhs as? Data {
      if lhs == rhs { return nil }
      // Compare Data objects lexicographically
      let minLength = min(lhs.count, rhs.count)
      for i in 0..<minLength {
        if lhs[i] != rhs[i] {
          return lhs[i] < rhs[i]
        }
      }
      return lhs.count < rhs.count
    }
    fatalError("Unsupported type: \(type(of: lhs)), \(type(of: rhs))")
  }

  public func getEntities<Entity: _Entity>(
    query: Query<Entity>,
    file: String,
    function: String,
    line: UInt
  ) async throws -> [Entity] {
    var cursor: Cursor?
    return try await getEntities(
      query: query, cursor: &cursor, file: file, function: function, line: line)
  }

  public func getKeys<Entity: _Entity>(
    query: Query<Entity>,
    cursor: inout Cursor?,
    file: String,
    function: String,
    line: UInt
  ) async throws -> [Entity.Key] {
    try await getEntities(query: query, cursor: &cursor, file: file, function: function, line: line)
      .map { $0.key }
  }

  public func getKeys<Entity: _Entity>(
    query: Query<Entity>,
    file: String,
    function: String,
    line: UInt
  ) async throws -> [Entity.Key] {
    var cursor: Cursor?
    return try await getKeys(
      query: query, cursor: &cursor, file: file, function: function, line: line)
  }

  private nonisolated func getValueFromValueType(
    _ valueType: Google_Datastore_V1_Value.OneOf_ValueType?
  ) -> Any {
    guard let valueType = valueType else {
      return NSNull()
    }

    switch valueType {
    case .nullValue:
      return NSNull()
    case .booleanValue(let value):
      return value
    case .integerValue(let value):
      return value
    case .doubleValue(let value):
      return value
    case .timestampValue(let value):
      return value
    case .keyValue(let value):
      return value
    case .stringValue(let value):
      return value
    case .blobValue(let value):
      return value
    case .geoPointValue(let value):
      return value
    case .entityValue(let value):
      return value
    case .arrayValue(let value):
      return value
    }
  }
}
