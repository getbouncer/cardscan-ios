Pod::Spec.new do |s|
  s.name             = 'CardScan'
  s.version          = '1.0.4034'
  s.summary          = 'Scan credit cards'
  s.description      = <<-DESC
CardScan is a library for scanning credit cards.
                       DESC

  s.homepage         = 'https://cardscan.io'
  s.license          = { :type => 'BSD', :file => 'LICENSE' }
  s.author           = { 'Sam King' => 'kingst@gmail.com' }
  s.source           = { :git => 'https://github.com/getbouncer/cardscan-ios.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/stk'

  s.swift_versions = ['4.0', '4.2']

  s.source_files = 'CardScan/Classes/**/*'
  s.resources = ['CardScan/Assets/*.xcassets', 'CardScan/Assets/*.storyboard']

  s.frameworks = 'AVKit', 'CoreML', 'VideoToolbox', 'Vision', 'UIKit', 'AVFoundation'

  s.subspec 'Stripe' do |stripe|
    stripe.dependency  'Stripe'
  end
end
