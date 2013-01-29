# RSpec tests for Augeas resources inside Puppet manifests

rspec-puppet-augeas is an extension of rodjek's popular rspec-puppet tool.  It
adds to your RSpec tests for a single class or define (or anything resulting in
a catalog) and allows you to run and test individual Augeas resources within it.

It takes a set of input files (fixtures) that the resource(s) will modify, runs
the resource, can verify it changed and is idempotent, then provides
Augeas-based tools to help verify the modification was made.

## Setting up

Install the gem first:

    gem install rspec-puppet-augeas

Extend your usual rspec-puppet class test, e.g. for the 'sshd' class:

    $ cat spec/classes/sshd_config_spec.rb
    describe 'sshd' do
      it 'should have an augeas resource' do
        should contain_augeas('root login')
      end

      # Expects Augeas['root login']
      describe_augeas 'root login' do
        it 'should change PermitRootLogin' do
          # Run the resource against the fixtures, check it changed
          should execute.with_change

          # Check changes in the file with aug_get and aug_match
          aug_get('PermitRootLogin').should == 'no'

          # Verify idempotence last to prevent false positive
          should execute.idempotently
        end
      end
    end

Copy original input files to `spec/fixtures/augeas` using the same filesystem
layout that the resource expects:

    $ tree spec/fixtures/augeas/
    spec/fixtures/augeas/
    `-- etc
        `-- ssh
            `-- sshd_config


Lastly, in your `spec/spec_helper.rb`, load ruby-puppet-augeas and configure the
fixtures directory.

    require 'rspec-puppet-augeas'
    RSpec.configure do |c|
      c.augeas_fixtures = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures', 'augeas')
    end

## Usage

Read the spec file(s) at `spec/classes/*.rb` to see various real-life examples
of the features below.

### describe\_augeas example group

`describe_augeas` adds an example group, like describe/context, but that describes
an Augeas resource from the catalog.  The description given to run\_augeas must
match the resource title.  `run_augeas` is a synonym. 

It takes optional hash arguments:

* `:fixtures` manages the files to run the resource against
  * a hash of fixtures to copy from the source (under augeas\_fixtures) to a
    destination path, e.g. `{ 'dest/file/location' => 'src/file/location' }`
  * a string of the source path, copied to the path given by the resource's
    `incl` parameter or `:target`
  * nil, by default copies all fixtures
* `:target` is the path of the file that the resource should modify 
* `:lens` is the lens to use when opening the target file (for `aug_*` etc.)

It sets the following variables inside examples:

* `resource` to the Puppet resource object
* `subject` (used implicitly) to an object representing the resource
* `output_root` to the path of the fixtures directory after one run

### execute matcher

The `execute` matcher is used to check how a resource has run, e.g.

    subject.should execute

(subject is implicit and so can be left out)

It has methods to add to the checks it performs:

* `with_change` ensures the resource was "applied" and didn't no-op
* `idempotently` runs the resource again to ensure it only applies once

### Test utilities

Helpers are provided to check the modifications made to files after applying
the resource.  Some require certain options, which can be supplied in the
`describe_augeas` statement or as arguments to the method.

* `output_root` returns the root directory of the modified fixtures
* `open_target` opens the target file and returns the handle, closes it too if
  given a block (expects `:target` option)
* `aug_open` opens the target file and returns an Augeas object, closes it too
  if given a block (expects `:target` and `:lens`)
* `aug_get(path)` runs `Augeas#get(path)` against the target file (expects
  `:target` and `:lens`), returns the value of the node
* `aug_match(path)` runs `Augeas#match(path)` against the target file (expects
  `:target` and `:lens`), returns an array of matches
* `augparse(result)` runs the augparse utility against the target file (expects
  `:target` and `:lens`) and verifies the file matches the `{ "key" = "value"
  }` augparse tree notation.  Call without an argument to get the current tree
  back.
  * `augparse()` raises error containing `{ "key" = "value" }` tree for the
    whole file
  * `augparse('{ "key" = "value" }')` verifies the target matches supplied tree
* `augparse_filter(filter, result)` takes the target file and all nodes matching
  the given filter, then runs the resulting file through augparse as above.
  * `augparse_filter('*[label()!="#comment"]')` raises error containing tree for
    the filtered file (all non-comment entries)
  * `augparse_filter('*[label()!="#comment"]', '{ "key" = "value" }')` verifies
    the filtered file (all non-comment entries) matches supplied tree

### RSpec configuration

New RSpec configuration options:

* `augeas_fixtures` is the path to the root of the fixtures directory
  containing source files

## Issues

Please file any issues or suggestions [on GitHub](https://github.com/domcleal/rspec-puppet-augeas/issues).
