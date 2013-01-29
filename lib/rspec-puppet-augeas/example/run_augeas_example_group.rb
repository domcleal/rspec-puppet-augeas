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
        args << { :type => :augeas }

        title = "Augeas[#{args.shift}]"
        describe(title, *args) do
          # inside here (the type augeas block), subject will be initialised
          # to the augeas resource object

          # initialise arguments passed into the run_augeas block
          target = options.delete(:target)
          let(:target) do
            target || resource[:incl]
          end

          lens = options.delete(:lens)
          let(:lens) do
            lens || resource[:lens]
          end

          fixture = options.delete(:fixture)
          let(:fixture) do
            if fixture and !fixture.is_a? Hash
              raise ArgumentError, ":target must be supplied" unless self.target
              fixture = { self.target => fixture.to_s }
            end
            fixture
          end

          class_exec(&block)
        end
      end

      # Synonym for run_augeas
      def describe_augeas(*args, &block)
        run_augeas(*args, &block)
      end
    end

    module InstanceMethods
      # Requires that the title of this example group is the resource title and
      # that the parent example group subject is a catalog (use rspec-puppet)
      def resource
        unless @resource
          title = self.class.description
          title = $1 if title =~ /^Augeas\[(.*)\]$/
          @resource = catalogue.resource('Augeas', title)
        end
        @resource
      end

      # Initialises the implicit example group 'subject' to a wrapped Augeas
      # resource
      def subject
        @subject ||= Resource.new(self.resource, fixture)
      end

      def output_root
        subject.root
      end
    end
  end
end
