require 'augeas'
require 'tempfile'
require 'tmpdir'

module RSpec::Puppet::Augeas
  module Fixtures
    # Copies test fixtures to a temporary directory
    # If file is nil, copies the entire augeas_fixtures directory
    # If file is a string, it copies that file from augeas_fixtures
    #   to the path being edited by the resource
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
      elsif file.is_a? Hash
        file.each do |dest,src|
          FileUtils.mkdir_p File.join(dir, File.dirname(dest))
          src = File.join(RSpec.configuration.augeas_fixtures, src) unless src.start_with? File::SEPARATOR
          FileUtils.cp_r src, File.join(dir, dest)
        end
      elsif file.respond_to? :to_s
        target = get_resource_target(resource)
        raise ArgumentError, "Unable to determine file being edited from #{resource.name}.  Supply :fixtures as a hash of { '/dest/path' => 'source/fixture/path' } instead." unless target
        FileUtils.mkdir_p File.join(dir, File.dirname(target))
        FileUtils.cp File.join(RSpec.configuration.augeas_fixtures, file.to_s), File.join(dir, target)
      end
    end

    # Take a best guess at the file the user's editing
    def get_resource_target(resource)
      return resource[:incl] if resource[:incl]
      # TODO: make reliable
      #return $1 if resource[:context] and resource[:context] =~ %r{/files(/.*)}
      nil
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
