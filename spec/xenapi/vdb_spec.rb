# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

class A; include XenAPI::Vdb; end

describe XenAPI::Vdb do
  subject { A.new }

  it "should contain the create_for method" do
    subject.should respond_to(:create_VDB_for)
  end
end
