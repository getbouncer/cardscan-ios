Pod::Spec.new do |s|
  s.name             = 'CardScan'
  s.version          = '2.0.2'
  s.summary          = 'Scan credit cards'
  s.description      = <<-DESC
CardScan is a library for scanning credit cards.
                       DESC

  s.homepage         = 'https://cardscan.io'
  s.license          = { :type => 'Custom', :file => 'LICENSE' }
  s.author           = { 'Sam King' => 'kingst@gmail.com' }
  s.source           = { :git => 'https://github.com/getbouncer/cardscan-ios.git', :tag => s.version.to_s } 

  # lint warning, who knows
  #s.social_media_url = 'https://twitter.com/stk'
  s.ios.deployment_target = '11.2'
  s.swift_version = '5.3.1'
  s.vendored_frameworks = 'build/CardVerify.xcframework'
  s.weak_frameworks = 'AVKit', 'CoreML', 'VideoToolbox', 'Vision', 'UIKit', 'AVFoundation'
end
