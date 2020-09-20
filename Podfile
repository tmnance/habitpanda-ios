DEPLOYMENT_VERSION = '12.0'.freeze
DEPLOYMENT_TARGET_KEY = 'IPHONEOS_DEPLOYMENT_TARGET'.freeze
PODS_MIN_DEPLOYMENT_VERSION = '12.0'.freeze

platform :ios, DEPLOYMENT_VERSION

target 'HabitPanda' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for HabitPanda
  pod 'Charts', '~> 3.5	'
  pod 'PopupDialog', '~> 1.1'
  pod 'SwipeCellKit', '~> 2.7'
  pod 'Toast-Swift', '~> 5.0'
end


# https://github.com/CocoaPods/CocoaPods/issues/7314#issuecomment-489453484
def fix_deployment_targets(installer)
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configuration_list.build_configurations.each do |config|
        if config.build_settings[DEPLOYMENT_TARGET_KEY].to_f < PODS_MIN_DEPLOYMENT_VERSION.to_f
          config.build_settings[DEPLOYMENT_TARGET_KEY] = PODS_MIN_DEPLOYMENT_VERSION
          puts "Successfully set #{DEPLOYMENT_TARGET_KEY} of target #{target.name} for config #{config.display_name} to #{PODS_MIN_DEPLOYMENT_VERSION}"
        end
      end
    end
  end
end

# Prevents warning "-pie being ignored. it is only used when linking a main executable"
def fix_pie_warnings(installer)
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Prevents warning "-pie being ignored. it is only used when linking a main executable"
      config.build_settings['LD_NO_PIE'] = 'NO'
    end
  end
end


post_install do |installer|
  fix_deployment_targets installer
  fix_pie_warnings installer
end
