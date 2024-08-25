Pod::Spec.new do |s|
  s.name             = 'SwiftAvroCore'
  s.version          = '0.1.0'
  s.description          = 'The SwiftAvroCore framework implements the core coding functionalities that are required in Apache Avro™. The schema format support Avro 1.8.2 and later Specification. It provides user-friendly Codable interface introduced from Swift 5 to encode and decode Avro schema, binray data as well as the JSON format data.'
  s.summary          = 'The SwiftAvroCore framework implements the core coding functionalities that are required in Apache Avro™.'
  s.homepage         = 'https://github.com/krikristoophe/SwiftAvroCore'
  s.license          = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author           = { 'Christophe Sonneville' => 'christophe.sonneville@devac.fr' }
  s.source           = { :git => 'https://github.com/krikristoophe/SwiftAvroCore.git', :tag => s.version.to_s }
  s.ios.deployment_target = '12.0'
  s.swift_version = '4.2'
  s.source_files = 'Sources/SwiftAvroCore/**/*'
  s.dependency 'Runtime', '2.2.7'
end
