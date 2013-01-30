require 'rspec-puppet-augeas/fixtures'

module RSpec::Puppet::Augeas
  class Resource
    attr_reader :resource, :txn, :txn_idempotent, :root, :logs, :logs_idempotent

    def initialize(resource, fixtures)
      @resource = resource
      @logs = []

      # The directory where the resource has run will be valuable, so keep it
      # for analysis and tests by the user
      @root = load_fixtures(resource, fixtures)
      ObjectSpace.define_finalizer(self, self.class.finalize(@root))

      resource[:root] = @root
      @txn = apply(resource, @logs)
    end

    def self.finalize(root)
      proc { FileUtils.rm_rf root }
    end

    # Run the resource a second time, against the output dir from the first
    #
    # @return [Puppet::Transaction] repeated transaction
    def idempotent
      @logs_idempotent = []
      root = load_fixtures(resource, {"." => "#{@root}/."})

      oldroot = resource[:root]
      resource[:root] = root
      @txn_idempotent = apply(resource, @logs_idempotent)
      FileUtils.rm_r root
      resource[:root] = oldroot

      @txn_idempotent
    end

    def to_s
      resource.to_s
    end

    private
    include RSpec::Puppet::Augeas::Fixtures
  end
end
