require 'augeas'
require 'tempfile'
require 'tmpdir'

module RSpec::Puppet::Augeas
  module Fixtures
    # Copies test fixtures to a temporary directory
    # If file is nil, copies the entire augeas_fixtures directory
    # If file is a hash, it copies the "value" from augeas_fixtures
    #   to each "key" path
    def load_fixtures(resource, file)
      if block_given?
        Dir.mktmpdir("rspec-puppet-augeas") do |dir|
          prepare_fixtures(dir, resource, file)
          yield dir
        end
      else
        dir = Dir.mktmpdir("rspec-puppet-augeas")
        prepare_fixtures(dir, resource, file)
        dir
      end
    end

    def prepare_fixtures(dir, resource, file)
      if file.nil?
        FileUtils.cp_r File.join(RSpec.configuration.augeas_fixtures, "."), dir
      else
        file.each do |dest,src|
          FileUtils.mkdir_p File.join(dir, File.dirname(dest))
          src = File.join(RSpec.configuration.augeas_fixtures, src) unless src.start_with? File::SEPARATOR
          FileUtils.cp_r src, File.join(dir, dest)
        end
      end
    end

    # Runs a particular resource via a catalog
    def apply(resource)
      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource resource
      catalog = catalog.to_ral if resource.is_a? Puppet::Resource
      catalog.apply
    end
  end
end
