# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

class A; include XenAPI::Vdi; end

describe XenAPI::Vdi do
  subject { A.new }

  it "should contain the create_for method" do
    subject.should respond_to(:create_VDI_for)
  end
end
