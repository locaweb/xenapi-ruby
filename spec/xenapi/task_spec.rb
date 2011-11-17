# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

class A; include XenAPI::Task; end

describe XenAPI::Task do
  subject { A.new }

  pending "Write real tests"

  it "should contain the task_record method" do
    subject.should respond_to(:task_record)
  end

  it "should contain the task_destroy method" do
    subject.should respond_to(:task_destroy)
  end

  it "should contain the task_create method" do
    subject.should respond_to(:task_create)
  end
end
