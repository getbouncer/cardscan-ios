Pod::Spec.new do |s|
  s.name             = 'CardScanPrivate'
  s.version          = '1.0.5043'
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
  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'

  s.source_files = 'CardScan/Classes/**/*'
  s.resource_bundles = { 'CardScan' => ['CardScan/Assets/*.xcassets', 'CardScan/Assets/*.storyboard', 'CardScan/Assets/*.mlmodelc'] }
  s.weak_frameworks = 'AVKit', 'CoreML', 'VideoToolbox', 'Vision', 'UIKit', 'AVFoundation'
end
