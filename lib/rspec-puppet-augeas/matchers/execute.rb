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
      if resource.txn.any_failed?
        "#{resource} fails when executing:\n#{format_logs(resource.logs)}"
      elsif change and !resource.txn.changed?.any?
        "#{resource} doesn't change when executed:\n#{format_logs(resource.logs)}"
      elsif idempotent and resource.idempotent.changed?.any?
        "#{resource} isn't idempotent, it changes on every run:\n#{format_logs(resource.logs_idempotent)}"
      end
    end

    def failure_message_for_should_not
      if resource.txn.any_failed?
        "#{resource} succeeds when executed:\n#{format_logs(resource.logs)}"
      elsif change and !resource.txn.changed?.any?
        "#{resource} changes when executed:\n#{format_logs(resource.logs)}"
      elsif idempotent and resource.idempotent.changed?.any?
        "#{resource} is idempotent, it doesn't change on every run:\n#{format_logs(resource.logs_idempotent)}"
      end
    end

    private

    def format_logs(logs)
      logs.map { |log| "#{log.level}: #{log.message}" }.join("\n")
    end
  end

  def execute
    Execute.new
  end
end
