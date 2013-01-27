require 'rspec-puppet-augeas/fixtures'

module RSpec::Puppet::Augeas
  module RunAugeasExampleGroup

    module ClassMethods
      # new example group, much like 'describe'
      #   title (arg #1) must match title of Augeas resource
      #   args may be hash containing:
      #     :fixture =>
      #       String -> relative path of source fixture file
      #       Hash   -> { "/dest/path" => "source/fixture/path", ... }
      def run_augeas(*args, &block)
        options = args.last.is_a?(::Hash) ? args.pop : {}
        fixture = options.delete(:fixture)

        title = "Augeas[#{args.shift}]"
        describe(title, *args, :type => :augeas) do
          # inside here (the type augeas block), subject will be initialised
          # to the augeas resource object

          # initialise fixture to the argument passed into the run_augeas block
          let(:fixture) { fixture }

          matcher :execute do
            @change = false
            @idempotent = false

            match do |resource|
              # TODO: is there a tidier way?
              include RSpec::Puppet::Augeas::Fixtures

              load_fixtures(resource, fixture) do |root|
                resource[:root] = root
                @txn = apply resource

                if @txn.any_failed?
                  false
                else
                  if @change
                    if @txn.changed?.any?
                      if @idempotent
                        @txn_idem = apply resource
                        @txn_idem.changed?.any?.should_not be_true
                        if @txn_idem.changed?.any?
                          false  # not idempotent
                        else
                          true  # idempotent
                        end
                      else
                        true  # changed, not idempotent
                      end
                    else
                      false  # didn't change
                    end
                  else
                    true  # no failure
                  end
                end
              end  # load_fixtures
            end

            # verifies the resource was 'applied'
            chain :with_change do
              @change = true
            end

            # verifies the resource only applies once
            chain :idempotently do
              @change = true
              @idempotent = true
            end

            description do
              if @idempotent
                "should change once only (idempotently)"
              elsif @change
                "should change successfully at least once"
              else
                "should execute without failure"
              end
            end

            failure_message_for_should do |resource|
              # FIXME: the branch should depend on outcome, not chaining
              if @idempotent
                "#{resource} isn't idempotent, it changes on every run"
              elsif @change
                "#{resource} doesn't change when executed"
              else
                "#{resource} fails when executed"
              end
            end

            failure_message_for_should_not do |resource|
              if @idempotent
                "#{resource} is idempotent, it doesn't change on every run"
              elsif @change
                "#{resource} changes when executed"
              else
                "#{resource} succeeds when executed"
              end
            end
          end

          class_exec(&block)
        end
      end
    end

    module InstanceMethods
      # Initialises the implicit example group 'subject' to an Augeas resource
      #
      # Requires that the title of this example group is the resource title and
      # that the parent example group subject is a catalog (use rspec-puppet)
      #
      # FIXME: return a wrapper class that will enable the matcher above to
      # access the resource still and run it, *plus* respond to aug_{get,match}
      # so we can write subject.aug_get("foo").should == "bar"
      def subject
        unless @resource
          catalog = super
          title = self.class.description
          title = $1 if title =~ /^Augeas\[(.*)\]$/
          @resource = catalog.resource('Augeas', title)
        end
        @resource
      end
    end
  end
end
