# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

class A; include XenAPI::Network; end

describe XenAPI::Network do
  subject { A.new }

  pending "Write real tests"

  it "should contain the network_name_label method" do
    subject.should respond_to(:task_create)
  end
end
