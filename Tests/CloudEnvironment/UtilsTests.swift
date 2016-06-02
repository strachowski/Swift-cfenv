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

@testable import CloudEnvironment

/**
* Online tool for escaping JSON: http://www.freeformatter.com/javascript-escape.html
* Online tool for removing new lines: http://www.textfixer.com/tools/remove-line-breaks.php
* Online JSON editor: http://jsonviewer.stack.hu/
*/
class UtilsTests : XCTestCase {

  static var allTests : [(String, UtilsTests -> () throws -> Void)] {
    return [
      ("testConvertStringToJSON", testConvertStringToJSON),
      ("testConvertJSONArrayToStringArray", testConvertJSONArrayToStringArray)
    ]
  }

  func testConvertStringToJSON() {
    let VCAP_APPLICATION = "{ \"users\": null,  \"instance_id\": \"7d4f24cfba06462ba23d68aaf1d7354a\",  \"instance_index\": 0,  \"host\": \"0.0.0.0\",  \"port\": 61263,  \"started_at\": \"2016-03-04 02:43:07 +0000\",  \"started_at_timestamp\": 1457059387 }"
    if let json = JSONUtils.convertStringToJSON(text: VCAP_APPLICATION) {
      //print("JSON object is: \(json)")
      //print("Type is \(json["users"].dynamicType)")
      XCTAssertNil(json["users"] as? AnyObject)
      XCTAssertEqual(json["instance_id"], "7d4f24cfba06462ba23d68aaf1d7354a", "instance_id should match.")
      XCTAssertEqual(json["instance_index"], 0, "instance_index should match.")
      XCTAssertEqual(json["host"], "0.0.0.0", "host should match.")
      XCTAssertEqual(json["port"], 61263, "port should match.")
      XCTAssertEqual(json["started_at"], "2016-03-04 02:43:07 +0000", "started_at should match.")
      XCTAssertEqual(json["started_at_timestamp"], 1457059387, "started_at_timestamp should match.")
    } else {
      XCTFail("Could not generate JSON object!")
    }
  }

  func testConvertJSONArrayToStringArray() {
    let jsonStr = "{ \"tags\": [ \"data_management\", \"ibm_created\", \"ibm_dedicated_public\" ] }"
    if let json = JSONUtils.convertStringToJSON(text: jsonStr) {
      let strArray: [String] = JSONUtils.convertJSONArrayToStringArray(json: json, fieldName: "tags")
        XCTAssertEqual(strArray.count, 3, "There should be 3 elements in the string array.")
        UtilsTests.verifyElementInArrayExists(strArray: strArray, element: "data_management")
        UtilsTests.verifyElementInArrayExists(strArray: strArray, element: "ibm_created")
        UtilsTests.verifyElementInArrayExists(strArray: strArray, element: "ibm_dedicated_public")
    } else {
      XCTFail("Could not generate JSON object!")
    }
  }

  private class func verifyElementInArrayExists(strArray: [String], element: String) {
    let index: Int? = strArray.index(of: element)
    XCTAssertNotNil(index, "Array should contain element: \(element)")
  }

 }
