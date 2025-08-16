import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2Posix
import GoogleCloudAuth
import GoogleCloudAuthGRPC
import GoogleCloudServiceContext
import Logging
import NIO
import ServiceLifecycle

public final class Datastore: DatastoreProtocol, Service {

  let logger = Logger(label: "datastore")

  private let authorization: Authorization?
  private let grpcClient: GRPCClient<HTTP2ClientTransport.Posix>
  let client: Google_Datastore_V1_Datastore.ClientProtocol

  public enum ConfigurationError: Error {
    case missingProjectID
  }

  public let projectID: String

  public convenience init() async throws {
    guard let projectID = await (ServiceContext.current ?? .topLevel).projectID else {
      throw ConfigurationError.missingProjectID
    }
    try self.init(projectID: projectID)
  }

  public init(projectID: String) throws {
    self.projectID = projectID

    if let host = ProcessInfo.processInfo.environment["DATASTORE_EMULATOR_HOST"] {
      let components = host.components(separatedBy: ":")
      let port = Int(components[1])!

      self.authorization = nil
      self.grpcClient = GRPCClient(
        transport: try .http2NIOPosix(
          target: .dns(host: components[0], port: port),
          transportSecurity: .plaintext,
          config: .defaults { config in
            config.backoff = .init(
              initial: .milliseconds(100),
              max: .seconds(1),
              multiplier: 1.6,
              jitter: 0.2
            )
            config.connection = .init(
              maxIdleTime: .seconds(30 * 60),
              keepalive: .init(
                time: .seconds(30),
                timeout: .seconds(5),
                allowWithoutCalls: true
              )
            )
          },
          serviceConfig: .init(
            methodConfig: [
              .init(
                names: [.init(service: "")],  // Empty service means all methods
                waitForReady: true,
                timeout: .seconds(60)
              )
            ]
          )
        )
      )
    } else {
      let authorization = Authorization(
        scopes: [
          "https://www.googleapis.com/auth/datastore"
        ], eventLoopGroup: .singletonMultiThreadedEventLoopGroup)

      self.authorization = authorization
      self.grpcClient = GRPCClient(
        transport: try .http2NIOPosix(
          target: .dns(host: "datastore.googleapis.com"),
          transportSecurity: .tls,
          config: .defaults { config in
            config.backoff = .init(
              initial: .milliseconds(100),
              max: .seconds(1),
              multiplier: 1.6,
              jitter: 0.2
            )
            config.connection = .init(
              maxIdleTime: .seconds(30 * 60),
              keepalive: .init(
                time: .seconds(30),
                timeout: .seconds(5),
                allowWithoutCalls: true
              )
            )
          },
          serviceConfig: .init(
            methodConfig: [
              .init(
                names: [.init(service: "")],  // Empty service means all methods
                waitForReady: true,
                timeout: .seconds(60)
              )
            ]
          )
        ),
        interceptors: [
          AuthorizationClientInterceptor(authorization: authorization)
        ]
      )
    }
    self.client = Google_Datastore_V1_Datastore.Client(wrapping: grpcClient)
  }

  public func run() async throws {
    try await withGracefulShutdownHandler {
      try await grpcClient.runConnections()
    } onGracefulShutdown: {
      self.grpcClient.beginGracefulShutdown()
    }

    try await authorization?.shutdown()
  }
}
