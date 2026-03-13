# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'PlantLight' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for PlantLight
  pod 'MMKV'
  pod 'Alamofire'
  pod 'KeychainAccess'
  pod 'SwiftyStoreKit'
  pod 'SwiftyJSON'
  pod 'SQLite.swift'
  pod 'YYModel'
  pod 'MBProgressHUD',:git => 'https://github.com/jdg/MBProgressHUD.git'
end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] ='13.0'
    end
  end
end
