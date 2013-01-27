require 'rspec-puppet-augeas'

RSpec.configure do |c|
  c.augeas_fixtures = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures', 'augeas')
  c.module_path = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures', 'modules')
  c.manifest_dir = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures', 'manifests')
end
