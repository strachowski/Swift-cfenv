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

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import XCTest
import Foundation
import SwiftyJSON

@testable import CFEnvironment

/**
* Very useful online tool for escaping JSON: http://www.freeformatter.com/javascript-escape.html
* Tool for removing new lines: http://www.textfixer.com/tools/remove-line-breaks.php
* JSON online editor: http://jsonviewer.stack.hu/
*/
class UtilsTests : XCTestCase {

  var allTests : [(String, () throws -> Void)] {
    return [
        ("testConvertStringToJSON", testConvertStringToJSON),
        ("testConvertJSONArrayToStringArray", testConvertJSONArrayToStringArray),
        ("testGetApp", testGetApp),
        ("testGetServices", testGetServices)
    ]
  }

  func testConvertStringToJSON() {
    let VCAP_APPLICATION = "{ \"users\": null,  \"instance_id\": \"7d4f24cfba06462ba23d68aaf1d7354a\",  \"instance_index\": 0,  \"host\": \"0.0.0.0\",  \"port\": 61263,  \"started_at\": \"2016-03-04 02:43:07 +0000\",  \"started_at_timestamp\": 1457059387 }"
    if let json = Utils.convertStringToJSON(VCAP_APPLICATION) {
      print("JSON object is: \(json)")
      //print("Type is \(json["users"].dynamicType)")
      XCTAssertNil(json["users"] as? AnyObject)
      XCTAssertEqual(json["instance_id"], "7d4f24cfba06462ba23d68aaf1d7354a")
      XCTAssertEqual(json["instance_index"], 0)
      XCTAssertEqual(json["host"], "0.0.0.0")
      XCTAssertEqual(json["port"], 61263)
      XCTAssertEqual(json["started_at"], "2016-03-04 02:43:07 +0000")
      XCTAssertEqual(json["started_at_timestamp"], 1457059387)
    } else {
      XCTFail("Could not generate JSON object!")
    }
  }

  func testConvertJSONArrayToStringArray() {
    //TODO
  }

  func testGetApp() {
    let options = "{ \"vcap\": { \"application\": { \"limits\": { \"mem\": 128, \"disk\": 1024, \"fds\": 16384 }, \"application_id\": \"e582416a-9771-453f-8df1-7b467f6d78e4\", \"application_version\": \"e5e029d1-4a1a-4004-9f79-655d550183fb\", \"application_name\": \"swift-test\", \"application_uris\": [ \"swift-test.mybluemix.net\" ], \"version\": \"e5e029d1-4a1a-4004-9f79-655d550183fb\", \"name\": \"swift-test\", \"space_name\": \"dev\", \"space_id\": \"b15eb0bb-cbf3-43b6-bfbc-f76d495981e5\", \"uris\": [ \"swift-test.mybluemix.net\" ], \"users\": null, \"instance_id\": \"7d4f24cfba06462ba23d68aaf1d7354a\", \"instance_index\": 0, \"host\": \"0.0.0.0\", \"port\": 61263, \"started_at\": \"2016-03-04 02:43:07 +0000\", \"started_at_timestamp\": 1457059387, \"start\": \"2016-03-04 02:43:07 +0000\", \"state_timestamp\": 1457059387 } } }"
    do {
      if let json = Utils.convertStringToJSON(options) {
        let appEnv = try CFEnvironment.getAppEnv(json)
        print(appEnv.app)
        let app = appEnv.getApp()
        print("app: \(app)")
        XCTAssertNotNil(app)
        XCTAssertEqual(app.port, 61263, "Port number should match.")
        XCTAssertEqual(app.id, "e582416a-9771-453f-8df1-7b467f6d78e4", "ID value should match.")
        XCTAssertEqual(app.version, "e5e029d1-4a1a-4004-9f79-655d550183fb", "Version number should match.")
        XCTAssertEqual(app.name, "swift-test", "App name should match.")
        XCTAssertEqual(app.instanceId, "7d4f24cfba06462ba23d68aaf1d7354a", "Instance ID value should match.")
        XCTAssertEqual(app.instanceIndex, 0, "Instance index value should match.")
        XCTAssertEqual(app.spaceId, "b15eb0bb-cbf3-43b6-bfbc-f76d495981e5", "Space ID value should match.")
        let limits = app.limits
        print("limits: \(limits)")
        XCTAssertNotNil(limits)
        XCTAssertEqual(limits!.memory, 128, "Memory value should match.")
        XCTAssertEqual(limits!.disk, 1024, "Disk value should match.")
        XCTAssertEqual(limits!.fds, 16384, "FDS value should match.")
        let uris = app.uris
        XCTAssertNotNil(uris)
        XCTAssertEqual(uris!.count, 1)
        XCTAssertEqual(uris![0], "swift-test.mybluemix.net")
        XCTAssertEqual(app.name, "swift-test", "App name should match.")
        let startedAt: NSDate? = app.startedAt
        XCTAssertNotNil(startedAt)
        let dateUtils = DateUtils()
        let startedAtStr = dateUtils.convertNSDateToString(startedAt)
        XCTAssertEqual(startedAtStr, "2016-03-04 02:43:07 +0000", "StartedAt date should match.")
        XCTAssertNotNil(app.startedAtTs, "StartedAt date should not be nil.")
        XCTAssertEqual(app.startedAtTs, 1457059387, "StartedAt ts should match.")
      } else {
        XCTFail("Could not generate JSON object!")
      }
    } catch let error as NSError {
      print("Error domain: \(error.domain)")
      print("Error code: \(error.code)")
      XCTFail("Could not get AppEnv object!")
    }
  }

  func testGetServices() {
    //TODO
  }

 }
