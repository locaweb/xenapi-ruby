# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

describe XenAPI::Session do
  before(:all) do
    @configs = YAML.load_file(File.dirname(__FILE__) + '/../../config/xenapi.yml')["xenapi"]
  end

  subject { XenAPI::Session.new(@configs["xenurl"]) }

  it "should process method_missing only if client is already authenticated" do
    expect{ subject.invalid_method }.to raise_error(XenAPI::UnauthenticatedClient)
  end

  context "when generating a proxy" do
    it "should undefine its copy method"
    it "should undefine its clone method"
    it "should add a prefix method to it"
  end

  describe "without custom block" do
    before do
      subject.login_with_password(@configs["user"], @configs["password"])
    end

    after do
      subject.close
    end

    it "should list VMs" do
      response = subject.VM.get_all
      response.should_not be_nil
      response.should respond_to("[]", "each")
      response.first.should =~ /^OpaqueRef:.*$/
    end

    it "should raise an error for invalid call by default" do
      code_block = lambda {subject.VM.get_all("arg that makes test to raise an error")}
      code_block.should raise_error(XenAPI::Error)
    end

    it "should raise an error if unable to login" do
      lambda { subject.login_with_password('','') }.should raise_error
    end
  end

  describe "with custom block" do
    subject do
      XenAPI::Session.new(@configs["xenurl"]) do |error, &called_method|
        @called_method = called_method
      end
    end

    before(:each) do
      subject.login_with_password(@configs["user"], @configs["password"])
    end

    after(:each) do
      subject.close
    end

    it "should not call block if no error happens" do
      subject.VM.get_all
      @called_method.should be_nil
    end

    it "should call block if any xen error happens" do
      subject.VM.get_all("arg that makes test to raise an error")
      @called_method.should be_a(Proc)
    end
  end

  describe "when no xen api is up" do
    it "should call block if can't connect" do
      @session = XenAPI::Session.new("https://169.167.161.160") do |error|
        @method_called = true
      end

      @session.login_with_password(@configs["user"], @configs["password"], 1)
      @method_called.should be_true
    end
  end
end
