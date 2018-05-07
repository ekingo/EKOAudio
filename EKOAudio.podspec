#
# Be sure to run `pod lib lint EKOAudio.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EKOAudio'
  s.version          = '1.0.0'
  s.summary          = 'audio transfer from amr/opus'

  s.description      = <<-DESC
                       DESC

  s.homepage         = 'https://github.com/ekingo/EKOAudio'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ekingo' => 'xhujin@163.com' }
  s.source           = { :git => 'git@to_be_edited/EKOAudio.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

    s.source_files = 'EKOAudio/**/*.{h,m,mm}','EKOAudio/*.{h,m,mm}'
  
  # s.resource_bundles = {
  #   'EKOAudio' => ['EKOAudio/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'Foundation'
end
