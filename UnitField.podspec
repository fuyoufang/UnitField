#
# Be sure to run `pod lib lint UnitField.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'UnitField'
  s.version          = '0.3.4'
  s.summary          = 'This is an elegant and concise password/verification code text field.'

  s.description      = <<-DESC
  This is an elegant and concise password/verification code text field. You can use UnitField just like UITextField.
                       DESC

  s.homepage         = 'https://github.com/fuyoufang/UnitField'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'fuyoufang' => 'fuyoufang@163.com' }
  s.source           = { :git => 'https://github.com/fuyoufang/UnitField.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'
  
  
  s.default_subspec = "Core"
  
  s.subspec "Core" do |ss|
      ss.dependency 'SnapKit', '~> 4.2.0'
      ss.source_files = 'UnitField/Classes/**/*'
      ss.framework  = "Foundation"
  end
  
  s.subspec 'Rx' do |rx|
      rx.dependency "UnitField/Core"
      rx.source_files = 'UnitField/Rx/**/*'
      rx.dependency 'RxSwift'
      rx.dependency 'RxCocoa'
  end

end
