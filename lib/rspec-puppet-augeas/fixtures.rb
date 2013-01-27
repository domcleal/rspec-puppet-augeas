require 'augeas'
require 'tempfile'

module RSpec::Puppet::Augeas
  module Fixtures
    # Copies test fixtures to a temporary directory
    # If file is nil, copies the entire augeas_fixtures directory
    # If file is a string, it copies that file from augeas_fixtures
    #   to the path being edited by the resource
    # If file is a hash, it copies the "value" from augeas_fixtures
    #   to each "key" path
    def load_fixtures(resource, file, &block)
      Dir.mktmpdir("rspec-puppet-augeas") do |dir|
        if file.nil?
          FileUtils.cp_r File.join(RSpec.configuration.augeas_fixtures, "."), dir
        elsif file.is_a? Hash
          file.each do |dest,src|
            FileUtils.mkdir_p File.join(dir, File.dirname(dest))
            FileUtils.cp File.join(RSpec.configuration.augeas_fixtures, src), File.join(dir, dest)
          end
        elsif file.respond_to? :to_s
          target = get_resource_target(resource)
          raise ArgumentError, "Unable to determine file being edited from #{resource.name}.  Supply :fixtures as a hash of { '/dest/path' => 'source/fixture/path' } instead." unless target
          FileUtils.mkdir_p File.join(dir, File.dirname(target))
          FileUtils.cp File.join(RSpec.configuration.augeas_fixtures, file.to_s), File.join(dir, target)
        end
        yield dir
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

    # Open Augeas on a given file.  Used for testing the results of running
    # Puppet providers.
    def aug_open(file, lens, &block)
      aug = Augeas.open(nil, AugeasProviders::Provider.loadpath, Augeas::NO_MODL_AUTOLOAD)
      begin
        aug.transform(
          :lens => lens,
          :name => lens.split(".")[0],
          :incl => file
        )
        aug.set("/augeas/context", "/files#{file}")
        aug.load!
        raise AugeasSpec::Error, "Augeas didn't load #{file}" if aug.match(".").empty?
        yield aug
      rescue Augeas::Error
        errors = []
        aug.match("/augeas//error").each do |errnode|
          aug.match("#{errnode}/*").each do |subnode|
            subvalue = aug.get(subnode)
            errors << "#{subnode} = #{subvalue}"
          end
        end
        raise AugeasSpec::Error, errors.join("\n")
      ensure
        aug.close
      end
    end
  end
end
