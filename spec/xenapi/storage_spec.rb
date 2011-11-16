# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

class A; include XenAPI::Storage; end

describe XenAPI::Storage do
  subject { A.new }

  it "should contain the storage_ref method" do
    subject.should respond_to(:storage_ref)
  end

  it "should contain the storage_record method" do
    subject.should respond_to(:storage_record)
  end

  it "should contain the storage_name method" do
    subject.should respond_to(:storage_name)
  end

  it "should contain the all_storages method" do
    subject.should respond_to(:all_storages)
  end
end
