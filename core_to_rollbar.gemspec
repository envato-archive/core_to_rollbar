Gem::Specification.new do |s|
  s.name        = 'core_to_rollbar'
  s.version     = '0.1.0'
  s.summary     = 'Submits the crash report to rollbar and forwards it to apport'
  s.authors     = ['Stan Pitucha']
  s.email       = 'stan.pitucha@envato.com'
  s.files       = ['lib/core_to_rollbar.rb']
  s.license     = 'MIT'
  s.executables << 'core_to_rollbar'
  s.add_runtime_dependency 'rollbar'
end
