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

    # Runs a particular resource via a catalog and stores logs in the caller's
    # supplied array
    def apply(resource, logs)
      logs.clear
      Puppet::Util::Log.newdestination(Puppet::Test::LogCollector.new(logs))
      Puppet::Util::Log.level = 'debug'

      oldconfdir = Puppet[:confdir]
      olduser = Puppet[:user]
      oldgroup = Puppet[:group]

      confdir = Dir.mktmpdir
      user = Etc.getpwuid(Process.uid).name
      group = Etc.getgrgid(Etc.getpwnam(user).gid).name

      Puppet[:confdir] = confdir
      if Process.uid != 0
        Puppet[:user] = user
        Puppet[:group] = group
      end

      [:require, :before, :notify, :subscribe].each { |p| resource.delete p }
      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource resource
      catalog = catalog.to_ral if resource.is_a? Puppet::Resource
      txn = catalog.apply

      Puppet::Util::Log.close_all
      txn
    ensure
      if confdir
        Puppet[:confdir] = oldconfdir
        FileUtils.rm_rf(confdir)
      end
      if user
        Puppet[:user] = olduser
      end
      if group
        Puppet[:group] = oldgroup
      end
    end
  end
end
