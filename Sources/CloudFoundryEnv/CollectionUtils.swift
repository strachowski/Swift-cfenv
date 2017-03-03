/**
* Copyright IBM Corporation 2017
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

extension Array
{
  func toDictionary<H:Hashable, T>(byTransforming transformer: (Element) -> (H, T)) -> Dictionary<H, T> {
    var result = Dictionary<H,T>()
    self.forEach({ element in
      let (key,value) = transformer(element)
      result[key] = value
    })
    return result
  }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
  func filterDictionaryUsingRegex(withRegex regex: String) -> Dictionary<Key, Value> {
    return self.filter({($0.key as! String).range(of: regex, options: .regularExpression) != nil}).toDictionary(byTransforming: {$0})
  }
}
