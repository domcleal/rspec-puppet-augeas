require 'rspec-puppet'

module RSpec::Puppet::Augeas
end

require 'rspec-puppet-augeas/example'
require 'rspec-puppet-augeas/matchers'

RSpec.configure do |c|
  c.add_setting :augeas_fixtures, :default => nil
end
