Pod::Spec.new do |s|
  s.name             = 'CardScan'
  s.version          = '1.0.4047'
  s.summary          = 'Scan credit cards'
  s.description      = <<-DESC
CardScan is a library for scanning credit cards.
                       DESC

  s.homepage         = 'https://cardscan.io'
  s.license          = { :type => 'BSD', :file => 'LICENSE' }
  s.author           = { 'Sam King' => 'kingst@gmail.com' }
  s.source           = { :git => 'https://github.com/getbouncer/cardscan-ios.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/stk'
  s.default_subspec = 'Core'
  s.ios.deployment_target = '10.0'
  s.swift_version = '4.2'
    
  s.subspec 'Core' do |core|
    core.source_files = 'CardScan/Classes/**/*'
    core.resource_bundles = { 'CardScan' => ['CardScan/Assets/*.xcassets', 'CardScan/Assets/*.storyboard', 'CardScan/Assets/*.bin'] }
    core.weak_frameworks = 'AVKit', 'CoreML', 'VideoToolbox', 'Vision', 'UIKit', 'AVFoundation'
  end

  s.subspec 'Stripe' do |stripe|
    stripe.source_files = 'CardScan/Classes/**/*'
    stripe.resource_bundles = { 'CardScan' => ['CardScan/Assets/*.xcassets', 'CardScan/Assets/*.storyboard', 'CardScan/Assets/*.bin'] }
    stripe.weak_frameworks = 'AVKit', 'CoreML', 'VideoToolbox', 'Vision', 'UIKit', 'AVFoundation'
    stripe.dependency  'Stripe'
  end
end
