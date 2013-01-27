require 'rspec-puppet-augeas/example/run_augeas_example_group'

RSpec::configure do |c|
  c.extend RSpec::Puppet::Augeas::RunAugeasExampleGroup::ClassMethods
  c.include RSpec::Puppet::Augeas::RunAugeasExampleGroup::InstanceMethods, :type => :augeas
end
