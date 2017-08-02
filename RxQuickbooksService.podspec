Pod::Spec.new do |s|
  s.name             = 'RxQuickbooksService'
  s.version          = '0.1.0'
  s.summary          = 'Reactive framework for handling Quickbooks calls'
  s.description      = <<-DESC
			Reactive framework for handling Quickbooks calls
                       DESC

  s.homepage         = 'https://github.com/ManuelAurora/RxQuickbooksService'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Manuel Aurora' => 'manuel4urora@gmail.com' }
  s.source           = { :git => 'https://github.com/ManuelAurora/RxQuickbooksService.git', :branch => 'master' }

  s.ios.deployment_target = '10.3'
  s.source_files = 'RxQuickbooksService/Classes/**/*'
  s.source_files = 'RxQuickbooksService/Classes/*.{swift}'
  s.frameworks = 'UIKit'	
  s.dependency   'SwiftyJSON'
  s.dependency 'OAuthSwift'
  s.dependency 'Alamofire'
  s.dependency 'RxSwift'
  s.dependency 'RxAlamofire'
  s.dependency 'Action'
  s.dependency 'RxCocoa'
  s.dependency 'OAuthSwiftAlamofire'
     
end
