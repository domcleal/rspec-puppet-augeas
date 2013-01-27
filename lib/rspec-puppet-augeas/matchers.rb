require 'rspec-puppet-augeas/matchers/execute'

RSpec::configure do |c|
  c.include RSpec::Puppet::Augeas::Matchers, :type => :augeas
end
