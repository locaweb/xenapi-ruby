# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

describe XenAPI::Dispatcher do
  FAKE_ERROR_MESSAGE = 'ERROR'
  FAKE_ERROR_DETAIL = 'WRONG METHOD'

  class FakeProxy
    def initialize
      @prefix = 'vm.'
    end

    def successful_call
      {'Status' => 'Success', 'Value' => :success}
    end

    def unsuccessful_call
      {'Status' => 'Failure', 'Value' => :failure, 'ErrorDescription' => [FAKE_ERROR_MESSAGE, FAKE_ERROR_DETAIL]}
    end
  end

  subject { XenAPI::Dispatcher.new(FakeProxy.new) }

  it "should forward any call to clone to method missing" do
    subject.should_receive(:method_missing).with(:clone)
    subject.clone
  end
  it "should forward any call to copy to method missing" do
    subject.should_receive(:method_missing).with(:copy)
    subject.copy
  end

  context "when sucessfully forwarding calls to the proxy" do
    it "should return 'value' from the response hash" do
      subject.successful_call.should == :success
    end
  end

  context "when failing to forward calls to the proxy" do
    it "should raise an error with the message returned by the result's 'ErrorDescription'" do
      expect{ subject.unsuccessful_call }.to raise_error(Exception, "#{FAKE_ERROR_MESSAGE}: #{FAKE_ERROR_DETAIL}")
    end

    context "with a callback" do
      before do
        @dispatcher = subject.class.new(FakeProxy.new) do |error, &original_call|
          rpc_proxy = mock(:rpc)
          rpc_proxy.should_receive(:retry_method)
          new_session = mock(:session)
          new_session.should_receive(:send).with(:vm).and_return(rpc_proxy)
          original_call.call(new_session)
        end
      end

      it "should call the callback passed as a block to the initializer and not raise an error" do
        @dispatcher.instance_variable_get(:@error_callback).should_receive(:call)
        lambda{@dispatcher.unsuccessful_call}.should_not raise_error
      end

      it "should create a new session and retry to call the missing method on the new session proxy" do
        @dispatcher.retry_method
      end
    end
  end
end
