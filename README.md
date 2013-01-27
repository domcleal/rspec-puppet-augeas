# RSpec tests for Augeas resources inside Puppet manifests

## Summary

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
      run_augeas 'root login' do
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

* run_augeas
  * fixtures
  * target, lens
* execute
  * with_change
  * idempotently
* TestUtils
  * output_root, open_target
  * aug_open, aug_get, aug_match
  * augparse, augparse_filter

## Issues

Please file any issues or suggestions [on GitHub](https://github.com/domcleal/rspec-puppet-augeas/issues).
