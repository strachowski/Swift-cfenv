# Swift-cfenv

The Swift-cfenv package provides classes and methods to parse Cloud Foundry-provided environment variables, such as the port number, IP address, and URL of the application. It also provides default values when running the application locally.

This library determines if you are running your application "locally" or on the cloud (i.e. Cloud Foundry app), based on whether the `VCAP_APPLICATION` environment variable is set. If not set, it is assumed you are running in "local" mode instead of "cloud mode".

For the implementation of this Swift package, we used as inspiration a similar module that had been developed for Node.js applications, [node-cfenv](https://github.com/cloudfoundry-community/node-cfenv).

## Usage
[Add description for the Package.swift file.]

```swift
import CFEnvironment

...

do {
  let appEnv = try CFEnvironment.getAppEnv()
  // Let's use the given port and binding host to create a socket for our server...
  let ip: String = appEnv.bind
  let port: UInt16 = UInt16(appEnv.port)

  ...

  // Once the server starts, print the url value
  print("Server is starting on \(appEnv.url).")

  ...

} catch CFEnvironmentError.InvalidValue {
  print("Oops, something went wrong... Server did not start!")
}
```

The code snippet above gets the binding host and port values through the AppEnv object, which were obtained from parsing the Cloud Foundry environment variables. These can then be used for biding the server. Also, the url value for the application, also obtained from environment variables, is used for logging purposes.

This library simplifies accessing the configuration values provided by Cloud Foundry.

## Running your application in Cloud Foundry vs. locally
The following environment variables, which are set when your application is running in Cloud Foundry, are inspected by the Swift-cfenv package:

- `VCAP_APPLICATION`
- `VCAP_SERVICES`
- `PORT`

If the `VCAP_APPLICATION` isn't set, it is then assumed that your application is running locally. For such cases, the AppEnv instance returns values that are still useful for starting your application. Therefore, this Swift package can be used when running in Cloud Foundry and when running locally.

## API
### `CFEnvironment`
To get an instance of the `AppEnv` class, you can use one of the following `CFEnvironment` class methods:

- `getAppEnv(options: JSON)`
- `getAppEnv()`

An instance of `AppEnv` class gives you access to the Cloud Foundry configuration data as an object.

The `options` JSON parameter can contain the following properties:

  - `name` - A string value for the name of the application. This value is used as the default name property of the `AppEnv` object. If the property is not specified, the `name` property of the `VCAP_APPLICATION` environment variable is used.
  - `protocol` - The protocol used in the generated URLs. It overrides the default protocol used when generating the URLs in the `AppEnv` object.
  - `vcap` - JSON object that provides values when running locally for the `VCAP_APPLICATION` and `VCAP_SERVICES` environment variables. This JSON object can have application and/or services properties, whose values are the same as the values serialized in the `VCAP_APPLICATION` and `VCAP_SERVICES` variables. Please, note that, when running locally, the `url` and `urls` properties of the `AppEnv` instance are not based on the `vcap` application object. Also, note that the `vcap` property is ignored if not running locally.

### `AppEnv`
An instance of the `AppEnv` class has the following properties:

- `isLocal`: Bool property is set to true if the VCAP_APPLICATION environment variable was set.
- `app`: A JSON object version of the VCAP_APPLICATION environment variable.
- `services`: A JSON object version of the VCAP_SERVICES environment variable.
- `name`: A string that contains the name of the application.
- `port`: An integer that contains the HTTP port number.
- `bind`: A string with the ip address for binding the server.
- `urls`: A string array that contains the URLs for accessing the servers.
- `url`: The first string in the urls array.

If no value can be determined for the `port` property, a default port of 8090 is assigned to it.

If running locally, the protocol used for the URLs will be `http`, otherwise it will be `https`. You can override this logic by specifying a particular protocol using the `protocol` property on the `options` parameter.

If the actual hostnames cannot be determined when running on the cloud (i.e. in Cloud Foundry), the url and urls values will have `localhost` as their hostname value.

The following are the instance methods for an `AppEnv` object:

- `getApp()`: Returns an App object that encapsulates the properties for the [VCAP_APPLICATION](https://docs.run.pivotal.io/devguide/deploy-apps/environment-variable.html#VCAP-APPLICATION) environment variable.

- `getServices()`: Returns all services bound to the application in a dictionary. The key in the dictionary is the name of the service, while the value is a Service object. Please note that this returned value is different than the `services` property returned from the `AppEnv` instance.

- `appEnv.getService(spec: String)`: Returns a Service object for the specified Cloud Foundry service. The `spec` parameter should be the name of the service or a regular expression to look up the service. If there is no service that matches the `spec` parameter, this method returns nil.

- `getServiceURL(spec: String, replacements: JSON?)`: Returns a service URL generated from the `VCAP_SERVICES` environment variable for the specified service or nil if service cannot be found. The `spec` parameter should be the name of the service or a regular expression to look up the service. The `replacements` parameter is a JSON object with the properties (e.g. `user`, `password`, `port`, etc.) found in Foundation's [NSURLComponents](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLComponents_class/index.html) class. To generate the service URL, the `url` property in the service credentials is first used to create an instance of the NSURLComponents class. The initial set of properties in the NSURLComponents instance can then be overridden by properties specified in the optional `replacements` JSON parameter. If there is not a `url` property in the service credentials, this method returns nil. Having said this, note that you have the capability to override the `url` property in the service credentials, with a `replacements` property of `url` and a value that specifies the name of the property in the service credentials that contains the base URL. For instance, you may find this useful in the case there is no `url` property in the service credentials.

- `appEnv.getServiceCreds(spec: String)`: Returns a JSON object that contains the credentials for the specified service. The `spec` parameter should be the name of the service or a regular expression to look up the service. If there is no service that matches the `spec` parameter, this method returns nil. In the case there is no credentials property for the specified service, an empty JSON object is returned.

### App
App is a structure that contains the following [`VCAP_APPLICATION`](https://docs.run.pivotal.io/devguide/deploy-apps/environment-variable.html#VCAP-APPLICATION) environment variable properties:

- `id`: A GUID string identifying the application.
- `name`: A string that contains the name assigned to the application.
- `uris`: A string array that contains the URIs assigned to the application.
- `version`: A GUID string identifying a version of the application.
- `instanceId`: A GUID string that identifies the application instance.
- `instanceIndex`: An integer that represents the index number of the instance.
- `limits`: A Limits object that contains memory, disk, and number of files for the application instance (see below).
- `port`: An integer that contains the port number of the application instance.
- `spaceId`: A GUID string identifying the application’s space.
- `startedAtTs`: An NSTimeInterval instance that contains the Unix epoch timestamp for the time the application instance was started.
- `startedAt`: An NSDate object that contains the time when the application instance was started.

### App.Limits
The App.Limits structure contains the memory, disk, and number of files for an application instance:

- `memory`: An integer that represents memory for the application (this value is commonly specified in the manifest file).
- `disk`: An integer that represents the disk space for the application (this value is commonly specified in the manifest file).
- `fds`: An integer that represents the number of files.

### Service
Service is a structure that contains the following properties for a Cloud Foundry [service](https://docs.run.pivotal.io/devguide/deploy-apps/environment-variable.html#VCAP-SERVICES):

- `name`: A string that contains the name assigned to the service instance.
- `label`: A string that contains the name of the service offering.
- `plan` : A string that states the service plan selected when the service instance was created.
- `tags`: An array of strings that contains values to identify a service instance.
- `credentials`: An optional JSON object that contains the service credentials required to access the service instance. Note that the credential properties for accessing a service could be completely different from one to another. For instance, the JSON credentials for a service may simply contain a `uri` property while the JSON credentials for another service may contain a `hostname`, `username`, and `password` properties.

## License
This Swift package is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
