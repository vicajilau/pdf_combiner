#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pdf_combiner.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pdf_combiner'
  s.version          = '0.0.1'
  s.summary          = 'is a lightweight and efficient Flutter plugin designed to merge multiple PDF documents into a single file effortlessly.'
  s.description      = <<-DESC
is a lightweight and efficient Flutter plugin designed to merge multiple PDF documents into a single file effortlessly.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'pdf_combiner/Sources/pdf_combiner/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'pdf_combiner_privacy' => ['pdf_combiner/Sources/pdf_combiner/PrivacyInfo.xcprivacy']}
end
