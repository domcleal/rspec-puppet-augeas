require 'spec_helper'

describe 'sshd' do
  it 'should have an augeas resource' do
    should contain_augeas('root login')
  end

  describe 'specify target+lens upfront, use all fixtures' do
    run_augeas 'root login', :lens => 'Sshd', :target => 'etc/ssh/sshd_config' do
      it 'should test resource' do
        aug_get('#comment[1]').should =~ /OpenBSD/
        open_target { |f| f.readline.should =~ /OpenBSD/ }

        should execute.with_change
        aug_get('PermitRootLogin').should == 'yes'
        open_target { |f| f.read.should =~ /^PermitRootLogin\s+yes$/ }

        should execute.idempotently
      end
    end
  end

  describe 'specify fixtures as a hash' do
    run_augeas 'root login', :fixture => { 'etc/ssh/sshd_config' => 'etc/ssh/sshd_config_2' } do
      it 'should test resource with second fixture' do
        aug_get('#comment[1]', :lens => 'Sshd', :target => 'etc/ssh/sshd_config').should == 'Fixture 2'
        should execute.with_change
        aug_get('PermitRootLogin', :lens => 'Sshd', :target => 'etc/ssh/sshd_config').should == 'yes'
        should execute.idempotently
      end
    end
  end

  describe 'specify target and non-standard fixture' do
    run_augeas 'root login', :lens => 'Sshd', :target => 'etc/ssh/sshd_config', :fixture => 'etc/ssh/sshd_config_2' do
      it 'should test resource with second fixture' do
        aug_get('#comment[1]').should == 'Fixture 2'
        should execute.with_change
        aug_get('PermitRootLogin').should == 'yes'
        should execute.idempotently
      end
    end
  end

  run_augeas 'fail to add root login' do
    it 'should fail to run entirely' do
      should_not execute
    end
  end

  run_augeas 'add root login', :lens => 'Sshd', :target => 'etc/ssh/sshd_config' do
    it 'should fail on idempotency' do
      should execute.with_change
      aug_match('PermitRootLogin').size.should == 2
      should_not execute.idempotently
    end
  end
end
