source 'https://rubygems.org'

gemspec

group :test do
  gem 'puppet'
  gem 'rake'
  gem 'simplecov'
  gem 'rspec', '< 3.2' if RUBY_VERSION < '1.9'
end

self.instance_eval(Bundler.read_file('Gemfile.local')) if File.exist? 'Gemfile.local'
