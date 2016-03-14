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

// TODO: Determine feasibility of returning structs/classes instead of
// dictionaries for the methods and instance variables exposed in this class.
public class AppEnv {

  let isLocal: Bool
  let app: [String:AnyObject]
  let services: [String:AnyObject]
  let port: Int
  let name: String?
  let bind: String
  let urls: [String]

  // Constructor
  public init(options: [String:AnyObject]) throws {
    // NSProcessInfo.processInfo().environment returns [String : String]
    let environmentVars = NSProcessInfo.processInfo().environment
    let vcapApplication = environmentVars["VCAP_APPLICATION"]
    isLocal = (vcapApplication == nil)

    // Get App
    if isLocal {
      if let appDictionary = options["vcap"]?["application"] as? [String:AnyObject] {
        app = appDictionary
      } else {
        app = [:]
      }
    } else {
       if let appDictionary = Utils.convertStringToDictionary(vcapApplication) {
         app = appDictionary
       } else {
         app = [:]
       }
    }

    // Get services
    let vcapServices = environmentVars["VCAP_SERVICES"]
    if isLocal {
      if let servicesDictionary = options["vcap"]?["services"] as? [String:AnyObject] {
        services = servicesDictionary
      } else {
        services = [:]
      }
    } else {
      if let servicesDictionary = Utils.convertStringToDictionary(vcapServices) {
        services = servicesDictionary
      } else {
         services = [:]
       }
    }

    // Get port
    var portString: String? = environmentVars["PORT"] ?? environmentVars["CF_INSTANCE_PORT"] ??
      environmentVars["VCAP_APP_PORT"] ?? nil

    if app["name"] == nil && portString == nil {
      portString = "8090"
    }

    var number: Int?
    if portString != nil {
      number = Int(portString!)
    }
    if number == nil {
        throw CFEnvironmentError.VariableNotFound
    }
    port = number!

    // Get name
    if let nameString = options["vcap"]?["name"] as? String {
      name = nameString
    } else if let nameString = app["name"] as? String {
      name = nameString
    } else {
      name = nil
    }

    // TODO: Add logic for parsing Package.swft and manifest.yml
    //https://github.com/behrang/YamlSwift

    // Get bind
    bind = (app["host"] != nil) ? app["host"] as! String : "localhost"

    // Get urls
    var uris: [String] = (app["uris"] != nil) ? app["uris"] as! [String] : []
    if isLocal {
      uris = ["localhost:\(port)"]
    } else {
      if (uris.count == 0) {
        uris = ["localhost"]
      }
    }

    let commProtocol: String = (options["protocol"] != nil) ?
      options["protocol"] as! String : isLocal ? "http" : "https"

    var tmpURLs: [String] = []
    for uri in uris {
       tmpURLs.append("\(commProtocol)//\(uri)");
    }
    urls = tmpURLs
  }

  /**
  * Returns all services bound to the application in a dictionary. The key in
  * the dictionary is the name of the service, while the value is a dictionary
  * object that contains all the properties for the service.
  */
  public func getServices() -> [String:[String:AnyObject]] {
    var results: [String:[String:AnyObject]] = [:]
    for (_, servs) in services {
      for service in servs as! [[String:AnyObject]] {
        if let name: String = service["name"] as? String {
          results[name] = service
        }
      }
    }
    return results
  }

  /**
  * Returns a dictionary with the properties for the specified Cloud Foundry
  * service. The spec parameter should be the name of the service
  * or a regex to look up the service. If there is no service that matches the
  * spec parameter, this method returns nil.
  */
  public func getService(spec: String) -> [String:AnyObject]? {
    let services = getServices()
    let service: [String:AnyObject]? = services[spec]
    if service != nil {
      return service
    }

    do {
      let regex = try NSRegularExpression(pattern: spec, options: NSRegularExpressionOptions.CaseInsensitive)
      for (name, serv) in services {
        let numberOfMatches = regex.numberOfMatchesInString(name, options: [], range: NSMakeRange(0, name.characters.count))
        if numberOfMatches > 0 {
          return serv
        }
      }
    } catch let error as NSError {
      print("Error code: \(error.code)")
    }

  	return nil
  }

  /**
  * Returns a URL generated from VCAP_SERVICES for the specified service or nil
  * if not found. The spec parameter should be the name of the service or a regex
  * to look up the service.
  *
  * The replacements parameter is a dictionary with the properties found in
  * Foundation's NSURLComponents class.
  */
  public func getServiceURL(spec: String, replacements: [String:AnyObject]?) -> String? {
    var substitutions: [String:AnyObject] = (replacements == nil) ? [:] : replacements!
    let service = getService(spec);
    let credentials = (service != nil) ? service!["credentials"] as? [String:AnyObject] : nil;
    if (credentials == nil) {
        return nil;
    }

    var url: String?
    if substitutions["url"] != nil {
      url = credentials![substitutions["url"] as! String] as? String
    } else if credentials!["url"] != nil {
      url = credentials!["url"] as? String
    } else if credentials!["uri"] != nil {
      url = credentials!["uri"] as? String
    } else {
      url = nil
    }

    if (url == nil) {
      return nil;
    }

    // TODO: Implement substitutions/replacements logic
    // References:
    // https://nodejs.org/api/url.html#url_url_format_urlobj
    // https://github.com/cloudfoundry-community/node-cfenv/blob/master/lib/cfenv.js
    // https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURL_Class/#//apple_ref/occ/instp/NSURL/scheme
    substitutions.removeValueForKey("url")
    let parsedURL = NSURLComponents(string: url!)
    if (parsedURL == nil) {
      return nil
    }

    for (key, substitution) in substitutions {
      print("\(key) : \(substitution)")
      // TODO: Update parsedURL object accordingly
      // Probably using reflection...
    }

    return parsedURL!.string
  }

  /**
  * Returns a dictionary that contains the credentials for the specified
  * Cloud Foundry service. The spec parameter should be the name of the service
  * or a regex to look up the service. If there is no service that matches the
  * spec parameter, this method returns nil. In the case there is no credentials
  * for the service, an empty dictionary is returned.
  */
  public func getServiceCreds(spec: String) -> [String:AnyObject]? {
    let service = getService(spec);
    if (service == nil) {
        return nil;
    }

    if let credentials = service!["credentials"] as? [String:AnyObject] {
      return credentials
    }

    return [:]
  }
}
