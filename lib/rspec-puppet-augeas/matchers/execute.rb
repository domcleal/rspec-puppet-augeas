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
      RSpec::Puppet::Coverage.cover!(resource)
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

    # verifies the resource only applies never or once at max
    def idempotently
      @idempotent = true
      self
    end

    def description
      if idempotent && change
        "change once only (idempotently)"
      elsif idempotent
        "change at most once (idempotently)"
      elsif change
        "change successfully at least once"
      else
        "execute without failure"
      end
    end

    def failure_message
      if resource.txn.any_failed?
        "#{resource} fails when executing:\n#{format_logs(resource.logs)}"
      elsif change and !resource.txn.changed?.any?
        "#{resource} doesn't change when executed:\n#{format_logs(resource.logs)}"
      elsif idempotent and resource.idempotent.changed?.any?
        "#{resource} isn't idempotent, it changes on every run:\n#{format_logs(resource.logs_idempotent)}"
      end
    end

    def failure_message_when_negated
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
      # Sometimes two transactions are run, sometimes one, so filter out the
      # first (it appears the idempotent test only sees one txn)
      if logs.map { |log| log.message }.grep(/Finishing transaction/).size > 1
        logs = logs.clone.drop_while { |log| log.message !~ /Finishing transaction/ }
        logs.shift
      end
      # Ignore everything after the txn end
      logs = logs.take_while { |log| log.message !~ /Finishing transaction/ }
      logs.map { |log| "#{log.level}: #{log.message}" }.join("\n")
    end
  end

  def execute
    Execute.new
  end
end
