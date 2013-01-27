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
      #     :target  => path of destination file to be modified
      #     :lens    => lens used for opening target
      def run_augeas(*args, &block)
        options = args.last.is_a?(::Hash) ? args.pop : {}

        title = "Augeas[#{args.shift}]"
        describe(title, *args, :type => :augeas) do
          # inside here (the type augeas block), subject will be initialised
          # to the augeas resource object

          # initialise arguments passed into the run_augeas block
          # TODO: target can be initialised from incl if available
          target = options.delete(:target)
          let(:target) { target }

          # TODO: ditto
          lens = options.delete(:lens)
          let(:lens) { lens }

          fixture = options.delete(:fixture)
          fixture = { target => fixture } if fixture.is_a? String and target
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
          title = self.class.description
          title = $1 if title =~ /^Augeas\[(.*)\]$/
          @resource = Resource.new(catalogue.resource('Augeas', title), fixture)
        end
        @resource
      end

      def output_root
        subject.root
      end
    end
  end
end
