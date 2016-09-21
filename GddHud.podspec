
#  Be sure to run `pod spec lint GddHud.podspec' to ensure this is a

Pod::Spec.new do |s|

  s.name         = "GddHud"
  s.version      = "1.1.2"
  s.summary      = "Popup library for iOS"
  s.platform     = :ios, '7.0'
  s.homepage     = "https://github.com/gdollardollar/gddhud.git"
  s.license      = "MIT"
  s.author             = { "gdollardollar" => "gdollardollar@gmail.com" }
  s.source       = { :git => "https://github.com/gdollardollar/gddhud.git", :tag => "#{s.version}" }

  s.source_files  = "GddHud/*.{h,m}"
  s.public_header_files = "GddHud/*.h"

  s.framework    = 'UIKit'

end
