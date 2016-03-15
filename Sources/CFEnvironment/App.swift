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
 * See https://docs.run.pivotal.io/devguide/deploy-apps/environment-variable.html#VCAP-SERVICES.
 */
public struct App {

  struct Limits {
    let memory: Int
    let disk: Int
    let fds: Int
  }

  let id: String
  let name: String
  let uris: [String]
  let version: String
  let host: String
  let instanceId: String
  let instanceIndex: Int
  let limits: Limits
  let port: Int
  let spaceId: String
  let startedAtTs: NSTimeInterval
  let startedAt: NSDate
}
