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

import PackageDescription

// Dual pathing for O/S differences
#if os(Linux)
   let swiftyJsonUrl = "https://github.com/IBM-Swift/SwiftyJSON.git"
   let swiftyJsonVersion = 3
#else
   let swiftyJsonUrl = "https://github.com/SwiftyJSON/SwiftyJSON.git"
   let swiftyJsonVersion = 2
#endif

let package = Package(
    name: "HelloWorldSwift",
    targets: [
      Target(name: "Utils", dependencies: []),
      Target(
        name: "CFEnvironment",
        dependencies: []
      ),
      Target(name: "Server", dependencies: [.Target(name: "Utils"), .Target(name: "CFEnvironment")])
    ],
    dependencies: [
      //.Package(url: "https://github.com/behrang/YamlSwift.git", majorVersion: 1),
      .Package(url: swiftyJsonUrl, majorVersion: swiftyJsonVersion)
    ],
    testDependencies: []
)
