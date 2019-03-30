Pod::Spec.new do |s|
  s.name             = 'CardScan'
  s.version          = '1.0.4034-beta'
  s.summary          = 'Scan credit cards'
  s.description      = <<-DESC
CardScan is a library for scanning credit cards.
                       DESC

  s.homepage         = 'https://cardscan.io'
  s.license          = { :type => 'BSD', :file => 'LICENSE' }
  s.author           = { 'Sam King' => 'kingst@gmail.com' }
  s.source           = { :git => 'https://github.com/getbouncer/cardscan-ios.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/stk'

  s.ios.deployment_target = '11.0'
  s.swift_version = '4.2'

  s.source_files = 'CardScan/Classes/**/*'
  s.resources = ['CardScan/Assets/*.xcassets', 'CardScan/Assets/*.storyboard']

  s.frameworks = 'AVKit', 'CoreML', 'VideoToolbox', 'Vision', 'UIKit', 'AVFoundation'

  #s.subspec 'Standard' do |standard|
    # blank, default configuration
  #end

  s.subspec 'Stripe' do |stripe|
    #stripe.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DCARDSCAN_STRIPE' }
    stripe.dependency  'Stripe'
  end
end
