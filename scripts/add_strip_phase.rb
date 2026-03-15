#!/usr/bin/env ruby
require 'xcodeproj'
project_path = File.expand_path('../macos/Runner.xcodeproj', File.dirname(__FILE__))
unless File.directory?(project_path)
  puts "HATA: Proje bulunamadi: #{project_path}"
  exit 1
end
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Runner' }
exit 1 unless target
existing = target.build_phases.find { |p| p.respond_to?(:name) && p.name == 'Strip Extended Attributes' }
if existing
  puts "Strip Extended Attributes zaten ekli."
  exit 0
end
script = "if [ -n \"$BUILT_PRODUCTS_DIR\" ] && [ -n \"$PRODUCT_NAME\" ]; then\n  APP_PATH=\"$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app\"\n  if [ -d \"$APP_PATH\" ]; then\n    xattr -cr \"$APP_PATH\"\n  fi\nfi\n"
phase = target.new_shell_script_build_phase('Strip Extended Attributes')
phase.shell_script = script
target.build_phases.delete(phase)
target.build_phases << phase
project.save
puts "Tamam: Strip Extended Attributes eklendi. Simdi: ./scripts/run_macos.sh"
