# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

class A; include XenAPI::Vbd; end

describe XenAPI::Vbd do
  subject { A.new }

  it "should contain the create_for method" do
    subject.should respond_to(:create_VBD_for)
  end
end
