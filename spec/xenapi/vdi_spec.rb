# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

class A; include XenAPI::Vdi; end

describe XenAPI::Vdi do
  subject { A.new }

  pending "Write real tests"

  it "should contain the create_for method" do
    subject.should respond_to(:create_VDI_for)
  end

  it "should contain the vdi_ref method" do
    subject.should respond_to(:vdi_ref)
  end

  it "should contain the vdi_record method" do
    subject.should respond_to(:vdi_record)
  end

  it "should contain the vdi_clone method" do
    subject.should respond_to(:vdi_clone)
  end

  it "should contain the vdi_virtual_size method" do
    subject.should respond_to(:vdi_virtual_size)
  end

  it "should contain the vdi_resize method" do
    subject.should respond_to(:vdi_resize)
  end

  it "should contain the vdi_name_label method" do
    subject.should respond_to(:vdi_name_label)
  end

  it "should contain the vdi_name_label= method" do
    subject.should respond_to(:vdi_name_label=)
  end

  it "should contain the vdi_name_description= method" do
    subject.should respond_to(:vdi_name_description=)
  end
end
