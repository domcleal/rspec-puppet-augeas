require 'rspec-puppet-augeas/fixtures'

module RSpec::Puppet::Augeas::Matchers
  # <subject>.should execute()
  #   where subject must be an Augeas resource
  class Execute
    attr_reader :resource, :idempotent, :change

    def initialize
      @change = false
      @idempotent = false
    end

    def matches?(resource)
      @resource = resource
      return false if resource.txn.any_failed?
      return false if change and !resource.txn.changed?.any?
      return false if idempotent and resource.idempotent.changed?.any?
      true
    end

    # verifies the resource was 'applied'
    def with_change
      @change = true
      self
    end

    # verifies the resource only applies once
    def idempotently
      @change = true
      @idempotent = true
      self
    end

    def description
      if idempotent
        "should change once only (idempotently)"
      elsif change
        "should change successfully at least once"
      else
        "should execute without failure"
      end
    end

    def failure_message_for_should
      # FIXME: the branch should depend on outcome, not chaining
      if idempotent
        "#{resource} isn't idempotent, it changes on every run"
      elsif change
        "#{resource} doesn't change when executed"
      else
        "#{resource} fails when executed"
      end
    end

    def failure_message_for_should_not
      if idempotent
        "#{resource} is idempotent, it doesn't change on every run"
      elsif change
        "#{resource} changes when executed"
      else
        "#{resource} succeeds when executed"
      end
    end
  end

  def execute
    Execute.new
  end
end
