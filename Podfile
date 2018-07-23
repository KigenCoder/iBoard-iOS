platform :ios, '9.0'

target 'iBoard' do
    use_frameworks!
    inhibit_all_warnings!
    
    # Pods for iBoard
    pod 'Alamofire', '~> 4.7'
    pod 'SwiftyJSON', '~> 4.0'
    pod 'SVProgressHUD'
    pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git'
    pod 'JTAppleCalendar', '~> 7.0'
    pod 'Popover'
    
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
        end
    end
end
