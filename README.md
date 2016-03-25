# Swift-cfenv

The Swift-cfenv package provides classes and methods to parse Cloud Foundry-provided environment variables, such as port number, host name/ip address, and URL of the application. It also provides default values when running the application locally.

This library determines if you are running your application "locally" or on the cloud (i.e. Cloud Foundry app), based on whether the VCAP_APPLICATION environment variable is set. If not set, it is assumed you are running in "local" mode instead of "cloud mode".

## Usage
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

The code snippet shown above binds the server to host and port values obtained from the Cloud Foundry environment variables. The url value, also obtained from environment variables, is used for logging purposes.

This library simplifies accessing the configuration values provided by Cloud Foundry.

As reference, see https://www.npmjs.com/package/cfenv.
