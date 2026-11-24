Pod::Spec.new do |spec|
 spec.author   = 'SIGN3 TECHNOLOGIES PRIVATE LIMITED'
 spec.homepage   = 'https://sign3.ai'
 spec.name     = 'Sign3Intelligence'
 spec.version   = '0.0.2002'
 spec.summary   = 'The Sign3 SDK is an iOS fraud prevention toolkit that assesses device security and detects risks to enhance protection against fraud.'
 spec.license = { :type => 'Custom', :text => 'Copyright 2024 SIGN3 TECHNOLOGIES PRIVATE LIMITED'}
 spec.platform   = :ios, "13"
 spec.source    = { :http => 'https://cdn.sign3.in/mobile-sdk/ios/intelligence/v0.0.2002/Sign3Intelligence.xcframework.zip' }
 spec.vendored_frameworks = 'Sign3Intelligence.xcframework'
end
