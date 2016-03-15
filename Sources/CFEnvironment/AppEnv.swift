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

  /**
  * The vcap option property is ignored if not running locally.
  */
  public init(options: [String:AnyObject]) throws {
    // NSProcessInfo.processInfo().environment returns [String : String]
    let environmentVars = NSProcessInfo.processInfo().environment
    let vcapApplication = environmentVars["VCAP_APPLICATION"]
    isLocal = (vcapApplication == nil)

    // Get app
    app = AppEnv.parseEnvVariable(isLocal, environmentVars: environmentVars,
      variableName: "VCAP_APPLICATION", varibleType: "application", options: options)

    // Get services
    services = AppEnv.parseEnvVariable(isLocal, environmentVars: environmentVars,
      variableName: "VCAP_SERVICES", varibleType: "services", options: options)

    // Get port
    port = try AppEnv.parsePort(environmentVars, app: app)

    // Get name
    name = AppEnv.parseName(app, options: options)

    // Get bind
    bind = app["host"] as? String ?? "localhost"

    // Get urls
    urls = AppEnv.parseURLs(isLocal, app: app, port: port, options: options)
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

  private class func parseEnvVariable(isLocal: Bool, environmentVars: [String:String],
    variableName: String, varibleType: String, options: [String:AnyObject])
    -> [String:AnyObject] {
    if isLocal {
      let dictionary = options["vcap"]?[varibleType] as? [String:AnyObject] ?? [:]
      return dictionary
    } else {
      let dictionary = Utils.convertStringToDictionary(environmentVars[variableName]) ?? [:]
      return dictionary
    }
  }

  private class func parsePort(environmentVars: [String:String], app: [String:AnyObject]) throws -> Int {
    var portString: String? = environmentVars["PORT"] ?? environmentVars["CF_INSTANCE_PORT"] ??
      environmentVars["VCAP_APP_PORT"] ?? nil

    if app["name"] == nil && portString == nil {
      portString = "8090"
    }

    let number: Int? = (portString != nil) ? Int(portString!) : nil
    if number == nil {
        throw CFEnvironmentError.VariableNotFound
    }
    return number!
  }

  private class func parseName(app: [String:AnyObject], options: [String:AnyObject]) -> String? {
    let name: String? = options["name"] as? String ?? app["name"] as? String

    // TODO: Add logic for parsing manifest.yml to get name
    // https://github.com/behrang/YamlSwift

    return name
  }

  private class func parseURLs(isLocal: Bool, app: [String:AnyObject], port: Int,
    options: [String:AnyObject]) -> [String] {
    var uris: [String] = app["uris"] as? [String] ?? []
    if isLocal {
      uris = ["localhost:\(port)"]
    } else {
      if (uris.count == 0) {
        uris = ["localhost"]
      }
    }

    let commProtocol: String = options["protocol"] as? String ?? (isLocal ? "http" : "https")
    var urls: [String] = []
    for uri in uris {
       urls.append("\(commProtocol)//\(uri)");
    }
    return urls
  }
}
