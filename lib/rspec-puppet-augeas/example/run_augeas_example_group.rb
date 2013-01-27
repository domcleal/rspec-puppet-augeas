require 'rspec-puppet-augeas/resource'

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

          class_exec(&block)
        end
      end
    end

    module InstanceMethods
      # Initialises the implicit example group 'subject' to an Augeas resource
      #
      # Requires that the title of this example group is the resource title and
      # that the parent example group subject is a catalog (use rspec-puppet)
      def subject
        unless @resource
          catalog = super
          title = self.class.description
          title = $1 if title =~ /^Augeas\[(.*)\]$/
          @resource = Resource.new(catalog.resource('Augeas', title), fixture)
        end
        @resource
      end
    end
  end
end
