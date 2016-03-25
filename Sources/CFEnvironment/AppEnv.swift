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

public class AppEnv {

  public let isLocal: Bool
  public let port: Int
  public let name: String?
  public let bind: String
  public let urls: [String]
  public let url: String
  public let app: JSON
  public let services: JSON

  /**
  * The vcap option property is ignored if not running locally.
  */
  public init(options: JSON) throws {
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

    // Get bind (IP address of the application instance)
    bind = app["host"].string ?? "0.0.0.0"

    // Get urls
    urls = AppEnv.parseURLs(isLocal, app: app, port: port, options: options)
    url = urls[0]
  }

  /**
  * Returns an App object.
  */
  public func getApp() -> App? {
    // Get limits
    let limits: App.Limits?
    let memory = app["limits"]["mem"].int
    let disk = app["limits"]["disk"].int
    let fds = app["limits"]["fds"].int
    if memory != nil && disk != nil && fds != nil {
      limits = App.Limits(memory: memory!,
        disk: disk!, fds: fds!)
    } else {
      limits = nil
    }

    // Get startedAt time
    let dateUtils = DateUtils()
    let startedAt: NSDate? = dateUtils.convertStringToNSDate(app["started_at"].string)
    let startedAtTs = startedAt?.timeIntervalSince1970

    // Get uris
    let uris = JSONUtils.convertJSONArrayToStringArray(app, fieldName: "uris")

    // Create App object
    let name = app["application_name"].string
    let id = app["application_id"].string
    let version = app["version"].string
    let instanceId = app["instance_id"].string
    let instanceIndex = app["instance_index"].int
    let port = app["port"].int
    let spaceId = app["space_id"].string

    // App instance should only be created if all required variables exist
    if limits != nil && startedAt != nil && startedAtTs != nil &&
      id != nil && name != nil && version != nil &&
      instanceId != nil && instanceIndex != nil && port != nil &&
      spaceId != nil {
        let appObj = App(id: id!, name: name!, uris: uris, version: version!,
          instanceId: instanceId!, instanceIndex: instanceIndex!,
          limits: limits!, port: port!, spaceId: spaceId!,
          startedAtTs: startedAtTs!, startedAt: startedAt!)
        return appObj
    }

    return nil
  }

  /**
  * Returns all services bound to the application in a dictionary. The key in
  * the dictionary is the name of the service, while the value is a Service
  * object that contains all the properties for the service.
  */
  public func getServices() -> [String:Service] {
    var results: [String:Service] = [:]
    for (_, servs) in services {
      for service in servs.arrayValue { // as! [[String:AnyObject]] {
        if let name: String = service["name"].string {
          let tags = JSONUtils.convertJSONArrayToStringArray(service, fieldName: "tags")
          results[name] = Service(name: name, label: service["label"].string!,
          plan: service["plan"].string!, tags: tags,
          credentials: service["credentials"])
        }
      }
    }
    return results
  }

  /**
  * Returns a Service object with the properties for the specified Cloud Foundry
  * service. The spec parameter should be the name of the service
  * or a regex to look up the service. If there is no service that matches the
  * spec parameter, this method returns nil.
  */
  public func getService(spec: String) -> Service? {
    let services = getServices()
    if let service = services[spec] {
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
  * if service is not found. The spec parameter should be the name of the
  * service or a regex to look up the service.
  *
  * The replacements parameter is a dictionary with the properties found in
  * Foundation's NSURLComponents class.
  * References:
  *   https://nodejs.org/api/url.html#url_url_format_urlobj
  *   https://github.com/cloudfoundry-community/node-cfenv/blob/master/lib/cfenv.js
  *   https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURL_Class/#//apple_ref/occ/instp/NSURL/scheme
  */
  public func getServiceURL(spec: String, replacements: JSON?) -> String? {
    var substitutions: JSON = replacements ?? [:]
    let service = getService(spec)
    let credentials = service?.credentials
    if (credentials == nil) {
        return nil;
    }

    let url: String?
    if substitutions["url"] != nil {
      url = credentials![substitutions["url"].string!].string
    } else {
      url = credentials!["url"].string ?? credentials!["uri"].string
    }

    if (url == nil) {
      return nil;
    }

    substitutions.dictionaryObject?.removeValueForKey("url")
    let parsedURL = NSURLComponents(string: url!)
    if (parsedURL == nil) {
      return nil
    }

    for (key, substitution) in substitutions {
      //print("\(key) : \(substitution)")
      switch key {
        case "user":
          parsedURL!.user = substitution.string
        case "password":
          parsedURL!.password = substitution.string
        case "port":
            parsedURL!.port = substitution.numberValue
        case "host":
          parsedURL!.host = substitution.string
        case "scheme":
          parsedURL!.scheme = substitution.string
        case "query":
          parsedURL!.query = substitution.string
        case "queryItems":
          let queryItems = substitution.arrayValue
          var urlQueryItems: [NSURLQueryItem] = []
          for queryItem in queryItems {
            if let name = queryItem["name"].string {
              let urlQueryItem = NSURLQueryItem(name: name, value: queryItem["value"].string)
              urlQueryItems.append(urlQueryItem)
            }
          }
          if urlQueryItems.count > 0 {
            parsedURL!.queryItems = urlQueryItems
          }
        // These are being ignored
        //case "fragment":
        // parsedURL!.fragment = substitution.string
        //case "path":
        // parsedURL!.path = substitution.string
        default:
          print("The replacements '\(key)' value was ignored.")
      }
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
  public func getServiceCreds(spec: String) -> JSON? {
    if let service = getService(spec) {
      if let credentials = service.credentials {
        return credentials
      } else {
        return [:]
      }
    } else {
      return nil
    }
  }

  /**
  * Static method for parsing VCAP_APPLICATION and VCAP_SERVICES.
  */
  private class func parseEnvVariable(isLocal: Bool, environmentVars: [String:String],
    variableName: String, varibleType: String, options: JSON)
    -> JSON {
    if isLocal {
      return options["vcap"][varibleType]
    } else {
      let json = JSONUtils.convertStringToJSON(environmentVars[variableName]) ?? [:]
      return json
    }
  }

  /**
  * Static method for parsing the port number.
  */
  private class func parsePort(environmentVars: [String:String], app: JSON) throws -> Int {
    var portString: String? = environmentVars["PORT"] ?? environmentVars["CF_INSTANCE_PORT"] ??
      environmentVars["VCAP_APP_PORT"] ?? nil

    if portString == nil {
      if app["name"].string == nil {
        portString = "8090"
      }
      //TODO: Are there any benefits in implementing logic similar to ports.getPort() (npm module)...?
      //portString = "" + (ports.getPort(appEnv.name));
      portString = "8090"
    }

    //let number: Int? = (portString != nil) ? Int(portString!) : nil
    if let number = Int(portString!) {
      return number
    } else {
      throw CFEnvironmentError.InvalidValue("Invalid PORT value: \(portString)")
    }
  }

  /**
  * Static method for parsing the name for the application.
  */
  private class func parseName(app: JSON, options: JSON) -> String? {
    let name: String? = options["name"].string ?? app["name"].string
    // TODO: Add logic for parsing manifest.yml to get name
    // https://github.com/behrang/YamlSwift
    // http://stackoverflow.com/questions/24097826/read-and-write-data-from-text-file
    return name
  }

  /**
  * Static method for parsing the URLs for the application.
  */
  private class func parseURLs(isLocal: Bool, app: JSON, port: Int,
    options: JSON) -> [String] {
    var uris: [String] = JSONUtils.convertJSONArrayToStringArray(app, fieldName: "uris")
    if isLocal {
      uris = ["localhost:\(port)"]
    } else {
      if (uris.count == 0) {
        uris = ["localhost"]
      }
    }

    let scheme: String = options["protocol"].string ?? (isLocal ? "http" : "https")
    var urls: [String] = []
    for uri in uris {
       urls.append("\(scheme)//\(uri)");
    }
    return urls
  }
}
