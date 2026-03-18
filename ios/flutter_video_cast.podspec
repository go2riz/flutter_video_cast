Pod::Spec.new do |s|
  s.name             = 'flutter_video_cast'
  s.version          = '1.0.4'
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
  s.dependency 'google-cast-sdk-no-bluetooth'
  s.platform         = :ios, '11.0'
  s.static_framework = true
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version    = '5.0'
end
