# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'HabitPanda' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for HabitPanda
  pod 'PopupDialog', '~> 1.1'
  pod 'SwipeCellKit'
  pod 'Toast-Swift', '~> 5.0.0'

end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Prevents warning "-pie being ignored. it is only used when linking a main executable"
      config.build_settings['LD_NO_PIE'] = 'NO'
    end
  end
end
