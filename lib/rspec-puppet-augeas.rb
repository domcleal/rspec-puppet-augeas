require 'rspec-puppet'
require 'rspec-puppet-augeas/example'

RSpec.configure do |c|
  c.add_setting :augeas_fixtures, :default => nil
end
