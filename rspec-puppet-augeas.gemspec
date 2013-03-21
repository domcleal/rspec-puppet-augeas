Gem::Specification.new do |s|
  s.name = 'rspec-puppet-augeas'
  s.version = '0.2.3'
  s.homepage = 'https://github.com/domcleal/rspec-puppet-augeas/'
  s.summary = 'RSpec tests for Augeas resources in Puppet manifests'
  s.description = 'RSpec tests for Augeas resources in Puppet manifests'

  s.files = [
    '.gitignore',
    'Gemfile',
    'LICENSE',
    'README.md',
    'Rakefile',
    'lib/rspec-puppet-augeas.rb',
    'lib/rspec-puppet-augeas/example.rb',
    'lib/rspec-puppet-augeas/example/run_augeas_example_group.rb',
    'lib/rspec-puppet-augeas/fixtures.rb',
    'lib/rspec-puppet-augeas/matchers.rb',
    'lib/rspec-puppet-augeas/matchers/execute.rb',
    'lib/rspec-puppet-augeas/resource.rb',
    'lib/rspec-puppet-augeas/test_utils.rb',
    'rspec-puppet-augeas.gemspec',
    'spec/classes/sshd_config_spec.rb',
    'spec/fixtures/augeas/etc/ssh/sshd_config',
    'spec/fixtures/augeas/etc/ssh/sshd_config_2',
    'spec/fixtures/manifests/site.pp',
    'spec/fixtures/modules/sshd/manifests/init.pp',
    'spec/spec_helper.rb'
  ]

  s.add_dependency 'rspec-puppet'
  s.add_dependency 'puppetlabs_spec_helper'

  s.authors = ['Dominic Cleal']
  s.email = 'dcleal@redhat.com'
end
