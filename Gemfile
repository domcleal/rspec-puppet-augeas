source 'https://rubygems.org'

gem 'puppetlabs_spec_helper'
#gem 'rspec-puppet', '< 1.0.0'
gem 'rspec-puppet'
gem 'ruby-augeas'

group :test do
  gem 'puppet'
  gem 'rake'
  gem 'simplecov'
end

self.instance_eval(Bundler.read_file('Gemfile.local')) if File.exist? 'Gemfile.local'
