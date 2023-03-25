[![Swift](https://github.com/STCData/SwiftAvroCore/actions/workflows/swift.yml/badge.svg)](https://github.com/STCData/SwiftAvroCore/actions/workflows/swift.yml)

# SwiftAvroCore

The SwiftAvroCore framework implements the core coding functionalities that are required in Apache Avro™. The schema format support Avro 1.8.2 and later Specification. It provides user-friendly Codable interface introduced from Swift 5 to encode and decode Avro schema, binray data as well as the JSON format data.

It is designed to achieve the following goals:

* to provide a small set of core functionalities defined in Avro specification;
* to make software development easier by introducing Codable interface;
* to provide platform independence and a self-contained framework to enhance portability.

This project, `SwiftAvroCore`, provides an implementation of the coding API for all Swift platforms which provide Foundation framework. The file IO and RPC functions defined in Avro specification will be provided in a seperate project `SwiftAvroRpc` which depends on the swift-nio framework.

## Getting Started

SwiftAvroCore uses SwiftPM as its build tool. If you want to depend on SwiftAvroCore in your own project, it's as simple as adding a dependencies clause to your Package.swift:

dependencies: [
.package(url: "https://github.com/lynixliu/SwiftAvroCore")
]
and then adding the SwiftAvroCore module to your target dependencies.

To work on SwiftAvroCore itself, or to investigate some of the demonstration applications, you can clone the repository directly and use SwiftPM to help build it. For example, you can run the following commands to compile and run the example:

swift build
swift test

To generate an Xcode project to work on SwiftAvroCore in Xcode:

swift package generate-xcodeproj

This generates an Xcode project using SwiftPM. You can open the project with:

open SwiftAvroCore.xcodeproj


## Using SwiftAvroCore

This guide assumes you have already installed a version of the latest [Swift binary distribution](https://swift.org/download/#latest-development-snapshots).
Suppose you have a schema in JSON format as shown below:
```
// The JSON schema
let jsonSchema = """
{"type":"record",
"fields":[
{"name": "requestId", "type": "int"},
{"name": "requestName", "type": "string"},
{"name": "parameter", "type": {"type":"array", "items": "int"}}
]}
"""
```

### Encoding and decoding

Here is a simple `main.swift` file which uses SwiftAvroCore. 
```
// main.swift
import Foundation
import SwiftAvroCore

// Define your model in Swift
struct Model: Encodable {
    let requestId: Int32 = 1
    let requestName: String = "hello"
    let parameter: [Int32] = []
}

// Make an Avro instance
let avro = Avro()
let myModel = Model(requestId: 42, requestName: "hello", parameter: [1,2])

// Decode schema from json
_ = avro.decodeSchema(schema: jsonSchema)!

// encode to avro binray
let binaryValue = try!avro.encode(myModel)

// decode from avro binary
let decodedValue: Model = try! avro.decode(from: binaryValue)

// check result
print("\(decodedValue.requestId), \(decodedValue.requestName), \(decodedValue.parameter)")

// decode from avro binary to Any Type in case of the receiving type unknown
let decodedAnyValue = try! avro.decode(from: binaryValue)

// check type
type(of: decodedAnyValue!)
```

Generate JSON schema for out side
```
let encodedSchema = try avro.encodeSchema(schema: schema)

print(String(bytes: encodedSchema!, encoding: .utf8)!)
```

### The Type mapping when Decode to Any type

Primitive type:

* null: nil
* boolean: Bool
* int: Int
* long: Int64
* float: Float
* double: Double
* bytes: [uint8]
* string: String
* fixed: [uint8] or [uint32] for Date

complex type: 

* array: [primitive type] or [Any]
* record: [String: primitive type] or [String:Any], the reflect in Swift is readonly, so we cannot generate struct in run time
* enum: String, value in symbols
* map: [String: <primitive type>] or [String: Any]
* union: optional type Any? or <primitive type>?

### File IO

```
// define codec
let codec = NullCodec(codecName: AvroReservedConstants.NullCodec)

// define 2 File Object Containers
var oc1 = try? ObjectContainer(schema: """
{
    "type": "record",
    "name": "test",
    "fields" : [
        {"name": "a", "type": "long"},
        {"name": "b", "type": "string"}]
}
""", codec: codec)
var oc2 = oc1

// test model
struct model: Codable {
    var a: UInt64 = 1
    var b: String = "hello"
}

// add model to container
try oc1?.addObject(model())

// encode object
let out = try! oc1?.encodeObject()

// write to file
try out?.write(to: URL(fileURLWithPath: "/location/to/save/file"))

// decode object heade
try oc2?.decodeHeader(from: out!)

// decode objec
let start = oc2?.findMarker(from: out!)
try oc2?.decodeBlock(from: out!.subdata(in: start!..<out!.count))

// the result: oc1?.blocks[0].data
```

### RPC

Please refer to Tests/SwiftAvroCoreTests/AvroRequestResponseTest.swift for detail

```
struct testArg {

// sample protocol
let supportProtocol: String = """
{
  "namespace": "com.acme",
  "protocol": "HelloWorld",
  "doc": "Protocol Greetings",
  "types": [
     {"name": "Greeting", "type": "record", "fields": [{"name": "message", "type": "string"}]},
     {"name": "Curse", "type": "error", "fields": [{"name": "message", "type": "string"}]}],
  "messages": {
    "hello": {
       "doc": "Say hello.",
       "request": [{"name": "greeting", "type": "Greeting" }],
       "response": "Greeting",
       "errors": ["Curse"]
    }
  }
}
"""

let arg = 
// client hash
let clientHash: [UInt8] = [UInt8]([0x0,0x1,0x2,0x3,0x4,0x5,0x6,0x7,0x8,0xA,0xB,0xC,0xD,0xE,0xF,0x10])

// server hash
let serverHash: [UInt8] = [UInt8]([0x1,0x1,0x2,0x3,0x4,0x5,0x6,0x7,0x8,0xA,0xB,0xC,0xD,0xE,0xF,0x10])

// create a conversation context
let context: Context = Context(requestMeta:[String: [UInt8]](),
                                   responseMeta:[String: [UInt8]]())
}

let arg = testArg() 

// create a server                                  
let server = try MessageResponse(context: arg.context, serverHash: arg.serverHash, serverProtocol: arg.supportProtocol)

// create a client
let client = try MessageRequest(context: arg.context, clientHash: arg.serverHash, clientProtocol: arg.supportProtocol)
        
// hand shake
let requestData = try client.encodeHandshakeRequest(request: HandshakeRequest(clientHash: arg.serverHash, clientProtocol: arg.supportProtocol, serverHash: arg.serverHash))
try client.addSession(hash: arg.serverHash, protocolString: arg.supportProtocol)
let (requestHandshake,resposeNone) = try server.resolveHandshakeRequest(requestData: requestData)
let (r, got) = try client.decodeResponse(responseData:resposeNone)

// request and response
struct requestMessage:Codable {
    var message: String = "requestData"
}

let requestMessageData = requestMessage()
let msgData = try client.writeRequest(messageName: "hello", parameters: [requestMessageData])
var expectData = Data()
expectData.append(contentsOf: [0,10]) // empty meta and length of message name
expectData.append("hello".data(using: .utf8)!) // message name
expectData.append(contentsOf: [22]) // length of message
expectData.append("requestData".data(using: .utf8)!) //message

let (requestHeader,request) = try server.readRequest(header: requestHandshake, from: msgData) as (RequestHeader, [requestMessage])

struct responseMessage:Codable {
    var message: String = "responseData"
}
let resMsg = responseMessage()
let resData = try server.writeResponse(header: requestHandshake, messageName: requestHeader.name, parameter: resMsg)
expectData = Data()
expectData.append(contentsOf: [0,0,24]) // empty meta, false flag and length of message name
expectData.append("responseData".data(using: .utf8)!)

let (responseHeader, gotResponse) = try client.readResponse(header: requestHandshake, messageName: "hello", from: resData)  as (ResponseHeader, [responseMessage])

// framing and deframing
var testData = Data([1,2,3,4,5])
testData.framing(frameLength: 4)
let deframed = testData.deFraming()

```


## License

This software is licensed under Apache 2.0 and Anti-996 License.

Please refer to below links for detail:

https://github.com/lynixliu/SwiftAvroCore/blob/master/LICENSE.txt
https://github.com/996icu/996.ICU/blob/master/LICENSE

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)


## FAQ

### Why this framework provided neigther code generation nor dynamic type?
There are a lot of serialization systems like Thrift, Protocol Buffers, or CORBA use the interface description languages (IDLs) to generate the code for users. Avro also provides an IDL to do so for static language such as C/C++ or Java. However, code generation is not flexiable for changing the message format frequently especially the project is in a cross team developing environment. Data in Avro is always stored with its corresponding schema, meaning we can always read a serialized item, regardless of whether we know the schema ahead of time. This allows us to perform serialization and deserialization without code generation. 
Most dynamic language implementation like Pyhon, ruby, javascript library do not support code generation but provide dynamic instance. However, the dynamic instance itself is a blackbox for users without checking the schema defination. There is no key name for the value, just value type. Set value to the dynamic instance looks more like assembly language which is hard to maintain without a lot of comments.  
This project provides neither of them because both of them are not elegent and simplicity. Thanks for the Codable feature introduced in Swift 4, allowing SwiftAvroCore to provide an easier to use and type safety interface for programmers. You can not only generate the schema from your Swift structure on the fly with Codable feature by JSONDecoder, but also encode/decode your data from Swift structure with Avro Codable feature by encoder/decoder. No need to write IDL or JSON schema, no need to generate code and no need to add extra comments or remember the key name. Besides, the Codable interface is also type safe, so you can locate bugs easilly.
That is it, enjoy the simplicity :)

### Why there is no  file IO and  RPC?
Because the file IO and RPC feature such as deflate depend on some specific platform and library. While the encoding feature depend nearly nothing except for Foundation which also required for swift runtime. So wrap the core features as a standalong framework is more portable and useful than a combo one.  
File IO and RPC will be provided in another private project `SwiftAvroRpc` which depends on the swift-nio framework. The project is still in developing. But I am about to move some parts of the modules which independent on the OS and third party package to this project.




