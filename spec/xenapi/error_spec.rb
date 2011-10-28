# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

describe XenAPI::Error do
  context "when dealing with Xen API errors" do
    it "should generate an XenAPI::AuthenticationError object for authentication error" do
      error_description = "SESSION_AUTHENTICATION_FAILED"
      error = XenAPI::ErrorFactory.create(*error_description)
      error.should be_instance_of(XenAPI::AuthenticationError)
    end

    it "should generate an XenAPI::ConnectionError object for host still booting error" do
      error_description = "HOST_STILL_BOOTING"
      error = XenAPI::ErrorFactory.create(*error_description)
      error.should be_instance_of(XenAPI::ConnectionError)
    end

    it "should generate an XenAPI::Error object for unknown error" do
      error_description = "UNKNWON_STATE"
      error = XenAPI::ErrorFactory.create(*error_description)
      error.should be_instance_of(XenAPI::Error)
    end

    context "for not master error" do
      before do
        error_description = ["HOST_IS_SLAVE", "10.11.0.11"]
        @error = XenAPI::ErrorFactory.create(*error_description)
      end

      it "should generate the right error" do
        @error.should be_instance_of(XenAPI::NotMasterError)
      end

      it "should parse not master error message and return master ip" do
        @error.master_ip.should == "10.11.0.11"
      end
    end
  end

  context "when selecting errors, it should generate a specific error message" do
    it "for expiration error" do
      expiration_error = EOFError.new "end of file reached"
      error = XenAPI::ErrorFactory.wrap(expiration_error)
      error.should be_instance_of(XenAPI::ExpirationError)
    end

    it "for timeout error" do
      expiration_error = Timeout::Error.new "execution expired"
      error = XenAPI::ErrorFactory.wrap(expiration_error)
      error.should be_instance_of(XenAPI::TimeoutError)
    end

    it "for XenAPI::Error instance" do
      xenapi_error = XenAPI::UnauthenticatedClient.new
      error = XenAPI::ErrorFactory.wrap(xenapi_error)
      error.should === xenapi_error
    end

    context "for connection error" do
      it "when host is unreachable" do
        connection_error = Errno::EHOSTUNREACH.new "No route to host"
        error = XenAPI::ErrorFactory.wrap(connection_error)
        error.should be_instance_of(XenAPI::ConnectionError)
      end

      it "when connection is refused" do
        connection_error = Errno::ECONNREFUSED.new "Connection refused – connect(2)"
        error = XenAPI::ErrorFactory.wrap(connection_error)
        error.should be_instance_of(XenAPI::ConnectionError)
      end

      it "when there is a broken pipe" do
        connection_error = Errno::EPIPE.new "Broken pipe"
        error = XenAPI::ErrorFactory.wrap(connection_error)
        error.should be_instance_of(XenAPI::ConnectionError)
      end
    end

    it "for generic error" do
      generic_error = RuntimeError.new "Generic Error"
      error = XenAPI::ErrorFactory.wrap(generic_error)
      error.should be_instance_of(XenAPI::Error)
    end
  end
end
