require 'rspec-puppet'

module RSpec::Puppet::Augeas
  class Error < StandardError
  end
end

require 'rspec-puppet-augeas/example'
require 'rspec-puppet-augeas/matchers'
require 'rspec-puppet-augeas/test_utils'

RSpec.configure do |c|
  c.add_setting :augeas_fixtures, :default => nil
  c.add_setting :augeas_lensdir, :default => nil
  c.include RSpec::Puppet::Augeas::TestUtils, :type => :augeas
end
