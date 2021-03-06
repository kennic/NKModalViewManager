#
# Be sure to run `pod lib lint NKModalViewManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NKModalViewManager'
  s.version          = '3.5.3'
  s.summary          = 'Present UIViewController modally'
  s.description      = <<-DESC
Present UIViewController modally easily and beautifully with animation.
                       DESC

  s.homepage         = 'https://github.com/kennic/NKModalViewManager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nam Kennic' => 'namkennic@me.com' }
  s.source           = { :git => 'https://github.com/kennic/NKModalViewManager.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/namkennic'

  s.ios.deployment_target = '8.0'

  s.source_files = 'NKModalViewController/**/*', 'NKFullscreenController/**/*'
  
end
