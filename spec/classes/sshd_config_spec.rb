require 'spec_helper'

# Tests all features of rspec-puppet-augeas against the class under
# spec/fixtures/module/sshd/manifests/init.pp
describe 'sshd' do
  # Basic rspec-puppet example
  it 'should have an augeas resource' do
    should contain_augeas('root login')
  end

  # Basic rspec-puppet-example
  #   uses all fixtures, lens + target are specified for aug_* functions to work
  describe 'specify target+lens upfront, use all fixtures' do
    describe_augeas 'root login', :lens => 'Sshd', :target => 'etc/ssh/sshd_config' do
      it 'should test resource' do
        # Verify this is the right fixture, using Augeas and simple parsing
        aug_get('#comment[1]').should =~ /OpenBSD/
        open_target { |f| f.readline.should =~ /OpenBSD/ }

        # Check it changes
        should execute.with_change
        aug_get('PermitRootLogin').should == 'yes'
        open_target { |f| f.read.should =~ /^PermitRootLogin\s+yes$/ }

        # Idempotency test last, as a broken resource may cause false positives
        should execute.idempotently
      end
    end
  end

  # Example of using a second fixture file to test a resource
  describe 'specify target and non-standard fixture' do
    describe_augeas 'root login', :lens => 'Sshd', :target => 'etc/ssh/sshd_config', :fixture => 'etc/ssh/sshd_config_2' do
      it 'should test resource with second fixture' do
        aug_get('#comment[1]').should == 'Fixture 2'

        # Example of increasing logging, which captures augeas provider's
        # debug logging on failure
        Puppet::Util::Log.level = 'debug'

        should execute.with_change
        aug_get('PermitRootLogin').should == 'yes'
        should execute.idempotently
      end
    end
  end

  # Fixtures can be a hash of destination path to source fixture path
  # Note that all paths are relative to augeas_fixtures (in spec_helper.rb)
  # and have no leading /
  #
  # Unusually, lens + target are specified on each aug_* function instead here.
  describe 'specify fixtures as a hash' do
    describe_augeas 'root login', :fixture => { 'etc/ssh/sshd_config' => 'etc/ssh/sshd_config_2' } do
      it 'should test resource with second fixture' do
        aug_get('#comment[1]', :lens => 'Sshd', :target => 'etc/ssh/sshd_config').should == 'Fixture 2'
        should execute.with_change
        aug_get('PermitRootLogin', :lens => 'Sshd', :target => 'etc/ssh/sshd_config').should == 'yes'
        should execute.idempotently
      end
    end
  end

  # When incl/lens are given on the resource, :target and :lens are resolved
  describe 'target detection from resource' do
    describe_augeas 'incl root login', :fixture => 'etc/ssh/sshd_config_2' do
      it 'should test resource with second fixture at incl location' do
        aug_get('#comment[1]').should == 'Fixture 2'
        should execute.with_change
        aug_get('PermitRootLogin').should == 'yes'
        should execute.idempotently
      end
    end
  end

  # Other test utilities:
  # augparse compares the entire fixture file to the { "key" = "value" } tree.
  # Call augparse with no argument initially and it will print out the tree
  # representation of the fixture file for reference.
  describe 'augparse' do
    describe_augeas 'root login', :lens => 'Sshd', :target => 'etc/ssh/sshd_config', :fixture => 'etc/ssh/sshd_config_2' do
      it 'should run augparse against the whole file' do
        should execute.with_change
        augparse('
          { "#comment" = "Fixture 2" }
          { "PermitRootLogin" = "yes" }
        ')
      end
    end
  end

  # augparse_filter first runs a filter against the fixture file before running
  # it through augparse.  Here, it filters out all non-comment entries.
  describe 'augparse_filter' do
    describe_augeas 'root login', :lens => 'Sshd', :target => 'etc/ssh/sshd_config', :fixture => 'etc/ssh/sshd_config_2' do
      it 'should filter non-comments' do
        should execute.with_change
        augparse_filter('*[label() != "#comment"]', '
          { "PermitRootLogin" = "yes" }
        ')
      end
    end
  end

  # Testing for deliberate failure
  describe_augeas 'fail to add root login' do
    it 'should fail to run entirely' do
      # Deliberate failure means this is inverted with "not"
      should_not execute

      # Verify the matcher message contains logs
      e = execute
      e.matches? subject
      e.description.should =~ /should execute/
      e.failure_message_for_should.should =~ /^err:.*false/
      e.failure_message_for_should_not.should =~ /^err:.*false/
      # Check for debug logs
      e.failure_message_for_should.should =~ /^debug:.*Opening augeas/
      # Ignore transaction stuff
      e.failure_message_for_should.split("\n").grep(/Finishing transaction/).empty?.should be_true
    end
  end

  # Testing for deliberate no-op
  run_augeas 'make no change' do
    it 'should fail on with_change' do
      should_not execute.with_change

      # Verify the matcher message contains logs
      e = execute
      e.with_change.matches? subject
      e.description.should =~ /should change successfully/
      e.failure_message_for_should.should =~ /doesn't change/
      e.failure_message_for_should_not.should =~ /changes/
    end
  end

  # Testing for deliberate idempotency failure
  run_augeas 'add root login', :lens => 'Sshd', :target => 'etc/ssh/sshd_config' do
    it 'should fail on idempotency' do
      should execute.with_change
      aug_match('PermitRootLogin').size.should == 2
      should_not execute.idempotently

      # Verify the matcher message contains logs
      e = execute
      e.idempotently.matches? subject
      e.description.should =~ /should change once only/
      e.failure_message_for_should.should =~ /^notice:.*success/
      e.failure_message_for_should_not.should =~ /^notice:.*success/
    end
  end
end
