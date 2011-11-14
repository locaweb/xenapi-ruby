# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

class A; include XenAPI::Storage; end

describe XenAPI::Storage do
  subject { A.new }

  it "should contain the ref method" do
    subject.should respond_to(:ref)
  end
end
