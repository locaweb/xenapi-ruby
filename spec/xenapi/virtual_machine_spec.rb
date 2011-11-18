# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

class A; include XenAPI::VirtualMachine; end

describe XenAPI::VirtualMachine do
  subject { A.new }

  before { subject.stub(:VM).and_return(@hypervisor_session = mock) }

  it "should call the xen clone method" do
    @hypervisor_session.should_receive(:clone).with("OpaqueRef:...","TheName")
    subject.vm_clone("OpaqueRef:...", "TheName")
  end

  it "should call the xen method to get the vm ref" do
    @hypervisor_session.should_receive(:get_by_uuid).with("262a2a64-3128-9e1a-1f05-49dc7012bb2c")
    subject.vm_ref("262a2a64-3128-9e1a-1f05-49dc7012bb2c")
  end

  it "should call the xen method to get the vm record" do
    @hypervisor_session.should_receive(:get_record).with("OpaqueRef:...")
    subject.vm_record("OpaqueRef:...")
  end
end
