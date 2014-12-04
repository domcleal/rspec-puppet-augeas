source 'https://rubygems.org'

gemspec

group :test do
  gem 'puppet'
  gem 'rake'
  gem 'simplecov'
end

self.instance_eval(Bundler.read_file('Gemfile.local')) if File.exist? 'Gemfile.local'
