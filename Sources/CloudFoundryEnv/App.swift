/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

 import Foundation

 /**
 * See https://docs.run.pivotal.io/devguide/deploy-apps/environment-variable.html#VCAP-APPLICATION.
 */
public struct App {

  public class Builder {
    var id: String?
    var name: String?
    var uris: [String]?
    var version: String?
    var instanceId: String?
    var instanceIndex: Int?
    var limits: Limits?
    var port: Int?
    var spaceId: String?
    var startedAt: Date? // Not provided on Diego

    init() {}

    func setId(id: String?) -> Builder {
      self.id = id
      return self
    }

    func setName(name: String?) -> Builder {
      self.name = name
      return self
    }

    func setUris(uris: [String]) -> Builder {
      self.uris = uris
      return self
    }

    func setVersion(version: String?) -> Builder {
      self.version = version
      return self
    }

    func setInstanceId(instanceId: String?) -> Builder {
      self.instanceId = instanceId
      return self
    }

    func setInstanceIndex(instanceIndex: Int?) -> Builder {
      self.instanceIndex = instanceIndex
      return self
    }

    func setLimits(limits: Limits) -> Builder {
      self.limits = limits
      return self
    }

    func setPort(port: Int?) -> Builder {
      self.port = port
      return self
    }

    func setSpaceId(spaceId: String?) -> Builder {
      self.spaceId = spaceId
      return self
    }

    func setStartedAt(startedAt: Date?) -> Builder {
      self.startedAt = startedAt
      return self
    }

    func build() -> App? {
      guard let id = id, let name = name,
      let uris = uris, let version = version,
      let instanceId = instanceId,
      let instanceIndex = instanceIndex,
      let limits = limits,
      let port = port,
      let spaceId = spaceId else {
          return nil
      }

      return App(id: id, name: name, uris: uris, version: version, instanceId: instanceId,
        instanceIndex: instanceIndex, limits: limits, port: port, spaceId: spaceId,
        startedAt: startedAt)
    }
  }

  public struct Limits {
    let memory: Int
    let disk: Int
    let fds: Int

    public init(memory: Int, disk: Int, fds: Int) {
      self.memory = memory
      self.disk = disk
      self.fds = fds
    }
  }

  public let id: String
  public let name: String
  public let uris: [String]
  public let version: String
  public let instanceId: String
  public let instanceIndex: Int
  public let limits: Limits
  public let port: Int
  public let spaceId: String
  public let startedAtTs: TimeInterval?
  public let startedAt: Date? // Not provided on Diego

  /**
  * Constructor.
  */
  // swiftlint:disable function_parameter_count
  private init(id: String, name: String, uris: [String], version: String,
    instanceId: String, instanceIndex: Int, limits: Limits, port: Int,
    spaceId: String, startedAt: Date?) {
  // swiftlint:enable function_parameter_count

    self.id = id
    self.name = name
    self.uris = uris
    self.version = version
    self.instanceId = instanceId
    self.instanceIndex = instanceIndex
    self.limits = limits
    self.port = port
    self.spaceId = spaceId
    self.startedAt = startedAt
    self.startedAtTs = startedAt?.timeIntervalSince1970
  }
}
