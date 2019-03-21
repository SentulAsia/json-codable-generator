//
//  CodableGenerator.swift
//  JSON Codable Generator
//
//  Created by Zaid Said on 20/03/2019.
//  Copyright © 2019 Zaid Said. All rights reserved.
//

import Foundation

struct CodableGenerator {
    
    static var shared = CodableGenerator()
    var codables: [String] = []
    
    private init() {}
    
    mutating func generate(fromInput input: [String: Any], withName name: String) -> String {
        codables = []
        var output = ""
        output += "//\n"
        output += "//  " + name.removeSpace + ".swift\n"
        output += "//  <Your App Name>\n"
        output += "//\n"
        output += "//  Created by <Your Name>\n"
        output += "//  Copyright © 2019 <Your Name>. All rights reserved.\n"
        output += "//\n"
        output += "\n"
        output += "\n"
        output += "//  Usage:\n"
        output += "//\n"
        output += "//  let " + name.camelCase + " = try? JSONDecoder().decode(" + name.removeSpace + ".self, from: jsonData)\n"
        output += "//  let jsonData = try? JSONEncoder().encode(" + name.camelCase + ")\n\n"
        output += "import Foundation\n\n"
        codables.append(generateCodable(fromInput: input, withName: name))
        for codable in codables.reversed() {
            output += codable
            output += "\n\n"
        }
        return output
    }
}

fileprivate extension String {
    var camelCase: String {
        return self.removeSpace.lowercaseFirstChar
    }
    
    var lowercaseFirstChar: String {
        return self.prefix(1).lowercased() + self.dropFirst()
    }
    
    var removeSpace: String {
        return self.replacingOccurrences(of: " ", with: "")
    }
    
    var removeUnderscore: String {
        return self.replacingOccurrences(of: "_", with: " ")
    }
}

private extension CodableGenerator {
    mutating func generateCodable(fromInput input: [String: Any], withName name: String) -> String {
        var output = ""
        output += "struct " + name.removeSpace + ": Codable {\n\n"
        output += generateProperties(fromInput: input)
        output += generateCodingKeys(fromInput: input)
        output += generateDictionaryDecoders(fromInput: input)
        output += generateDecoders(fromInput: input)
        output += generateDictionaryEncoders(fromInput: input)
        output += generateEncoders(fromInput: input)
        output += "}"
        return output
    }
    
    mutating func generateProperties(fromInput input: [String: Any]) -> String {
        var output = ""
        for i in input.sorted(by: { $0.key < $1.key } ) {
            output += generateProperty(fromInput: i)
        }
        return output
    }
    
    mutating func generateProperty(fromInput input: (key: String, value: Any)) -> String {
        var output = ""
        let name = generateVariableName(fromString: input.key)
        if let codableArray = input.value as? [[String: Any]] {
            codables.append(generateCodable(fromInput: codableArray.first!, withName: input.key.removeUnderscore.capitalized))
            output += "    let " + name + ": [" + generateCodableName(fromString: input.key) + "]?\n"
        } else if let _ = input.value as? [Double] {
            output += "    let " + name + ": [Decimal]?\n"
        } else if let _ = input.value as? [Int] {
            output += "    let " + name + ": [Int]?\n"
        } else if let stringArray = input.value as? [String] {
            if let url = URL(string: stringArray.first!), let _ = try? url.checkResourceIsReachable() {
                output += "    let " + name + ": [URL]?\n"
            } else {
                output += "    let " + name + ": [String]?\n"
            }
        } else if let codable = input.value as? [String: Any] {
            codables.append(generateCodable(fromInput: codable, withName: input.key.removeUnderscore.capitalized))
            output += "    let " + name + ": " + generateCodableName(fromString: input.key) + "?\n"
        } else if let _ = input.value as? Double {
            output += "    let " + name + ": Decimal?\n"
        } else if let _ = input.value as? Int {
            output += "    let " + name + ": Int?\n"
        } else if let string = input.value as? String {
            if let url = URL(string: string), let _ = try? url.checkResourceIsReachable() {
                output += "    let " + name + ": URL?\n"
            } else {
                output += "    let " + name + ": String?\n"
            }
        }
        return output
    }
    
    func generateVariableName(fromString string: String) -> String {
        return string.removeUnderscore.capitalized.camelCase.removeSpace
    }
    
    func generateCodableName(fromString string: String) -> String {
        return string.removeUnderscore.capitalized.removeSpace
    }
    
    func generateCodingKeys(fromInput input: [String: Any]) -> String {
        var output = "\n    enum CodingKeys: String, CodingKey {\n"
        for i in input.sorted(by: { $0.key < $1.key } ) {
            output += generateCodingKey(fromInput: i)
        }
        output += "    }\n"
        return output
    }
    
    func generateCodingKey(fromInput input: (key: String, value: Any)) -> String {
        var output = ""
        output += "        case " + generateVariableName(fromString: input.key) + " = \"" + input.key + "\"\n"
        return output
    }
    
    func generateDictionaryDecoders(fromInput input: [String: Any]) -> String {
        var output = "\n    init(from dictionary: [String: Any]) {\n"
        output += "        let keys = CodingKeys.self\n"
        for i in input.sorted(by: { $0.key < $1.key } ) {
            output += generateDictionaryDecoder(fromInput: i)
        }
        output += "    }\n"
        return output
    }
    
    func generateDictionaryDecoder(fromInput input: (key: String, value: Any)) -> String {
        var output = ""
        let name = generateVariableName(fromString: input.key)
        if let _ = input.value as? [[String: Any]] {
            output += "        " + name + " = [" + generateCodableName(fromString: input.key) + "]()\n"
            output += "        if let " + name + "Array = dictionary[keys." + name + ".rawValue] as? [[String: Any]] {\n"
            output += "            for dic in " + name + "Array {\n"
            output += "                " + name + "?.append(" + generateCodableName(fromString: input.key) + "(from: dic))\n"
            output += "            }\n"
            output += "        }\n"
        } else if let _ = input.value as? [Double] {
            output += "        " + name + " = [Decimal]()\n"
            output += "        if let " + name + "Array = dictionary[keys." + name + ".rawValue] as? [NSNumber] {\n"
            output += "            for dic in " + name + "Array {\n"
            output += "                " + name + "?.append(dic.decimalValue)\n"
            output += "            }\n"
            output += "        }\n"
        } else if let _ = input.value as? [Int] {
            output += "        " + name + " = [Int]()\n"
            output += "        if let " + name + "Array = dictionary[keys." + name + ".rawValue] as? [Int] {\n"
            output += "            for dic in " + name + "Array {\n"
            output += "                " + name + "?.append(dic)\n"
            output += "            }\n"
            output += "        }\n"
        } else if let stringArray = input.value as? [String] {
            if let url = URL(string: stringArray.first!), let _ = try? url.checkResourceIsReachable() {
                output += "        " + name + " = [URL]()\n"
                output += "        if let " + name + "Array = dictionary[keys." + name + ".rawValue] as? [String] {\n"
                output += "            for dic in " + name + "Array {\n"
                output += "                if let value = URL(string: dic) {\n"
                output += "                    " + name + "?.append(value)\n"
                output += "                }\n"
                output += "            }\n"
                output += "        }\n"
            } else {
                output += "        " + name + " = [String]()\n"
                output += "        if let " + name + "Array = dictionary[keys." + name + ".rawValue] as? [String] {\n"
                output += "            for dic in " + name + "Array {\n"
                output += "                " + name + "?.append(dic)\n"
                output += "            }\n"
                output += "        }\n"
            }
        } else if let _ = input.value as? [String: Any] {
            output += "        if let " + name + "Data = dictionary[keys." + name + ".rawValue] as? [String: Any] {\n"
            output += "            " + name + " = " + generateCodableName(fromString: input.key) + "(from: " + name + "Data)\n"
            output += "        } else {\n"
            output += "            " + name + " = nil\n"
            output += "        }\n"
        } else if let _ = input.value as? Double {
            output += "        " + name + " = (dictionary[keys." + name + ".rawValue] as? NSNumber)?.decimalValue\n"
        } else if let _ = input.value as? Int {
            output += "        " + name + " = dictionary[keys." + name + ".rawValue] as? Int\n"
        } else if let string = input.value as? String {
            if let url = URL(string: string), let _ = try? url.checkResourceIsReachable() {
                output += "        " + name + " = dictionary[keys." + name + ".rawValue] as? URL\n"
            } else {
                output += "        " + name + " = dictionary[keys." + name + ".rawValue] as? String\n"
            }
        }
        return output
    }
    
    func generateDecoders(fromInput input: [String: Any]) -> String {
        var output = "\n    init(from decoder: Decoder) throws {\n"
        output += "        let values = try decoder.container(keyedBy: CodingKeys.self)\n"
        for i in input.sorted(by: { $0.key < $1.key } ) {
            output += generateDecoder(fromInput: i)
        }
        output += "    }\n"
        return output
    }
    
    func generateDecoder(fromInput input: (key: String, value: Any)) -> String {
        var output = ""
        let name = generateVariableName(fromString: input.key)
        if let _ = input.value as? [[String: Any]] {
            output += "        " + name + " = try values.decodeIfPresent([" + generateCodableName(fromString: input.key) + "].self, forKey: ." + name + ")\n"
        } else if let _ = input.value as? [Double] {
            output += "        " + name + " = try values.decodeIfPresent([Decimal].self, forKey: ." + name + ")\n"
        } else if let _ = input.value as? [Int] {
            output += "        " + name + " = try values.decodeIfPresent([Int].self, forKey: ." + name + ")\n"
        } else if let stringArray = input.value as? [String] {
            if let url = URL(string: stringArray.first!), let _ = try? url.checkResourceIsReachable() {
                output += "        " + name + " = try values.decodeIfPresent([URL].self, forKey: ." + name + ")\n"
            } else {
                output += "        " + name + " = try values.decodeIfPresent([String].self, forKey: ." + name + ")\n"
            }
        } else if let _ = input.value as? [String: Any] {
            output += "        " + name + " = try values.decodeIfPresent(" + generateCodableName(fromString: input.key) + ".self, forKey: ." + name + ")\n"
        } else if let _ = input.value as? Double {
            output += "        " + name + " = try values.decodeIfPresent(Decimal.self, forKey: ." + name + ")\n"
        } else if let _ = input.value as? Int {
            output += "        " + name + " = try values.decodeIfPresent(Int.self, forKey: ." + name + ")\n"
        } else if let string = input.value as? String {
            if let url = URL(string: string), let _ = try? url.checkResourceIsReachable() {
                output += "        " + name + " = try values.decodeIfPresent(URL.self, forKey: ." + name + ")\n"
            } else {
                output += "        " + name + " = try values.decodeIfPresent(String.self, forKey: ." + name + ")\n"
            }
        }
        return output
    }
    
    func generateDictionaryEncoders(fromInput input: [String: Any]) -> String {
        var output = "\n    func toDictionary() -> [String: Any] {\n"
        output += "        let keys = CodingKeys.self\n"
        output += "        var dictionary = [String: Any]()\n"
        for i in input.sorted(by: { $0.key < $1.key } ) {
            output += generateDictionaryEncoder(fromInput: i)
        }
        output += "        return dictionary\n"
        output += "    }\n"
        return output
    }
    
    func generateDictionaryEncoder(fromInput input: (key: String, value: Any)) -> String {
        var output = ""
        let name = generateVariableName(fromString: input.key)
        if let _ = input.value as? [[String: Any]] {
            output += "        if let " + name + " = " + name + " {\n"
            output += "            var dictionaryElements = [[String:Any]]()\n"
            output += "            for " + name + "Element in " + name + " {\n"
            output += "                dictionaryElements.append(" + name + "Element.toDictionary())\n"
            output += "            }\n"
            output += "            dictionary[keys." + name + ".rawValue] = dictionaryElements\n"
            output += "        }\n"
        } else if let _ = input.value as? [NSNumber] {
            output += "        if let " + name + " = " + name + " {\n"
            output += "            var dictionaryElements = [NSNumber]()\n"
            output += "            for " + name + "Element in " + name + " {\n"
            output += "                dictionaryElements.append(" + name + "Element)\n"
            output += "            }\n"
            output += "            dictionary[keys." + name + ".rawValue] = dictionaryElements\n"
            output += "        }\n"
        } else if let _ = input.value as? [String] {
            output += "        if let " + name + " = " + name + " {\n"
            output += "            var dictionaryElements = [String]()\n"
            output += "            for " + name + "Element in " + name + " {\n"
            output += "                dictionaryElements.append(" + name + "Element)\n"
            output += "            }\n"
            output += "            dictionary[keys." + name + ".rawValue] = dictionaryElements\n"
            output += "        }\n"
        } else if let _ = input.value as? [String: Any] {
            output += "        if let " + name + " = " + name + " {\n"
            output += "            dictionary[keys." + name + ".rawValue] = " + name + ".toDictionary()\n"
            output += "        }\n"
        } else if let _ = input.value as? NSNumber {
            output += "        if let " + name + " = " + name + " {\n"
            output += "            dictionary[keys." + name + ".rawValue] = " + name + "\n"
            output += "        }\n"
        } else if let _ = input.value as? String {
            output += "        if let " + name + " = " + name + " {\n"
            output += "            dictionary[keys." + name + ".rawValue] = " + name + "\n"
            output += "        }\n"
        }
        return output
    }
    
    func generateEncoders(fromInput input: [String: Any]) -> String {
        var output = "\n    func encode(to encoder: Encoder) throws {\n"
        output += "        var container = encoder.container(keyedBy: CodingKeys.self)\n"
        for i in input.sorted(by: { $0.key < $1.key } ) {
            output += generateEncoder(fromInput: i)
        }
        output += "    }\n"
        return output
    }
    
    func generateEncoder(fromInput input: (key: String, value: Any)) -> String {
        var output = ""
        let name = generateVariableName(fromString: input.key)
        output += "        try container.encodeIfPresent(" + name + ", forKey: ." + name + ")\n"
        return output
    }
}
