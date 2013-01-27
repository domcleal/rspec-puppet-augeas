require 'augeas'
require 'tempfile'

module RSpec::Puppet::Augeas
  module TestUtils
    def open_target(opts = {})
      file = opts[:target] || self.target or raise ArgumentError, ":target must be supplied"
      f = File.open(File.join(self.output_root, file))
      return f unless block_given?
      yield f
      f.close
    end

    def aug_get(path, opts = {})
      aug_open(opts) do |aug|
        aug.get(path)
      end
    end

    def aug_match(path, opts = {})
      aug_open(opts) do |aug|
        aug.match(path)
      end
    end

    # Open Augeas on a given file, by default the target / lens specified in
    # options to the run_augeas block
    def aug_open(opts = {})
      file = opts[:target] || self.target or raise ArgumentError, ":target must be supplied"
      file = "/#{file}" unless file.start_with? '/'
      lens = opts[:lens] || self.lens or raise ArgumentError, ":lens must be supplied"
      lens = "#{lens}.lns" unless lens.include? '.'
      root = opts[:root] || self.output_root

      aug = Augeas.open(root, nil, Augeas::NO_MODL_AUTOLOAD)
      begin
        aug.transform(
          :lens => lens,
          :name => lens.split(".")[0],
          :incl => file
        )
        aug.set("/augeas/context", "/files#{file}")
        aug.load!
        raise RSpec::Puppet::Augeas::Error, "Augeas didn't load #{file}" if aug.match(".").empty?
        yield aug
      rescue Augeas::Error
        errors = []
        aug.match("/augeas//error").each do |errnode|
          aug.match("#{errnode}/*").each do |subnode|
            subvalue = aug.get(subnode)
            errors << "#{subnode} = #{subvalue}"
          end
        end
        raise RSpec::Puppet::Augeas::Error, errors.join("\n")
      ensure
        aug.close
      end
    end

    # Creates a simple test file, reads in a fixture (that's been modified by
    # the resource) and runs augparse against the expected tree.
    def augparse(result = "?", opts = {})
      file = opts[:target] || self.target or raise ArgumentError, ":target must be supplied"
      file = File.join(self.output_root, file) unless file.start_with? '/'
      lens = opts[:lens] || self.lens or raise ArgumentError, ":lens must be supplied"
      lens = "#{lens}.lns" unless lens.include? '.'

      Dir.mktmpdir("rpa-augparse") do |dir|
        # Augeas always starts with a blank line when creating new files, so
        # reprocess file and remove it to make writing tests easier
        File.open("#{dir}/input", "w") do |finput|
          File.open(file, "r") do |ffile|
            line = ffile.readline
            finput.write line unless line == "\n"
            ffile.each {|line| finput.write line }
          end
        end

        # Test module, Augeas reads back in the input file
        testaug = "#{dir}/test_rspec_puppet_augeas.aug"
        File.open(testaug, "w") do |tf|
          tf.write(<<eos)
module Test_Rspec_Puppet_Augeas =
  test #{lens} get Sys.read_file "#{dir}/input" =
    #{result}
eos
        end

        output = %x(augparse #{testaug} 2>&1)
        raise RSpec::Puppet::Augeas::Error, "augparse failed:\n#{output}" unless $? == 0 && output.empty?
      end
    end

    # Takes a full fixture file, loads it in Augeas, uses the relative path
    # and/or filter and saves just that part in a new file.  That's then passed
    # into augparse and compared against the expected tree.  Saves creating a
    # tree of the entire file.
    #
    # Because the filtered fragment is saved in a new file, seq labels will reset
    # too, so it'll be "1" rather than what it was in the original fixture.
    def augparse_filter(filter = "*[label()!='#comment']", result = "?", opts = {})
      file = opts[:target] || self.target or raise ArgumentError, ":target must be supplied"
      file = File.join(self.output_root, file) unless file.start_with? '/'
      lens = opts[:lens] || self.lens or raise ArgumentError, ":lens must be supplied"
      lens = "#{lens}.lns" unless lens.include? '.'

      # duplicate the original since we use aug.mv
      tmpin = Tempfile.new("rpa-original")
      tmpin.write(File.read(file))
      tmpin.close

      tmpout = Tempfile.new("rpa-filtered")
      tmpout.close

      aug_open(opts.merge(:root => '/', :target => tmpin.path)) do |aug|
        # Load a transform of the target, so Augeas can write into it
        aug.transform(
          :lens => lens,
          :name => lens.split(".")[0],
          :incl => tmpout.path
        )
        aug.load!
        tmpaug = "/files#{tmpout.path}"
        raise RSpec::Puppet::Augeas::Error, "Augeas didn't load empty file #{tmpout.path}" if aug.match(tmpaug).empty?

        # Check the filter matches something and move it
        ftmatch = aug.match(filter)
        raise RSpec::Puppet::Augeas::Error, "Filter #{filter} within #{file} matched #{ftmatch.size} nodes, should match at least one" if ftmatch.empty?

        begin
          # Loop on aug_match as path indexes will change as we move nodes
          fp = ftmatch.first
          aug.mv(fp, "#{tmpaug}/#{fp.split(/\//)[-1]}")
          ftmatch = aug.match(filter)
        end while not ftmatch.empty?

        aug.save!
      end

      augparse(result, opts.merge(:root => '/', :target => tmpout.path))
    ensure
      tmpin.unlink if tmpin
      tmpout.unlink if tmpout
    end
  end
end
