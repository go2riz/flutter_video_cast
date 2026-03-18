Pod::Spec.new do |s|
  s.name             = 'flutter_video_cast'
  s.version          = '1.0.5'
  s.summary          = 'Flutter plugin for Chromecast and AirPlay buttons and control.'
  s.description      = <<-DESC
Flutter plugin to discover cast devices like Chromecast and Apple TV,
show native cast buttons, and control media playback sessions.
                       DESC
  s.homepage         = 'https://github.com/PalaTeam/flutter_video_cast'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'PalaTeam' => 'opensource@palateam.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'

  use_legacy_cast_pod = ENV['FLUTTER_VIDEO_CAST_USE_LEGACY_IOS_CAST_POD'] == '1'
  cast_pod_name = use_legacy_cast_pod ? 'google-cast-sdk-no-bluetooth' : 'google-cast-sdk-no-bluetooth-xcframework'
  cast_pod_version = use_legacy_cast_pod ? '~> 4.8' : '~> 4.8'
  minimum_ios_version = use_legacy_cast_pod ? '13.0' : '15.0'

  s.dependency cast_pod_name, cast_pod_version
  s.platform         = :ios, minimum_ios_version
  s.static_framework = true
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version    = '5.0'
end
