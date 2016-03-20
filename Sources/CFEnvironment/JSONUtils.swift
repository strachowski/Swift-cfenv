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
import SwiftyJSON

/**
* JSON utilities.
*/
public class JSONUtils {

  /**
  * Converts the speficied string to a JSON object.
  */
  public class func convertStringToJSON(text: String?) -> JSON? { //-> [String:AnyObject]? {
    if let data = text?.dataUsingEncoding(NSUTF8StringEncoding) {
      let json = JSON(data: data)
      return json
    }
    print("Could not generate JSON object from string: \(text)")
    return nil

    // if let data = text?.dataUsingEncoding(NSUTF8StringEncoding) {
    //   do {
    //     let dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String:AnyObject]
    //     print("Value returned from method is: \(dictionary)")
    //     return dictionary
    //   } catch  let error as NSError {
    //     print("Error code: \(error.code)")
    //     return nil
    //   }
    // }
    // return nil
  }

  /**
  * Converts a JSON array to an array of Strings.
  */
  public class func convertJSONArrayToStringArray(json: JSON, fieldName: String) -> [String] {
    return json[fieldName].arrayValue.map { $0.stringValue }
  }
}
