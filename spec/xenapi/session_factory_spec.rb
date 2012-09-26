# -*- coding: UTF-8 -*-
require File.dirname(__FILE__) + "/../spec_helper"

describe SessionFactory do
  it "should call XenAPI with valid credentials" do
    ip = '192.168.0.1'
    username = 'john'
    password = 'doe'

    xen_api = mock(:xen_api)
    xen_api.should_receive(:login_with_password).with(username, password)
    XenAPI::Session.should_receive(:new).with("https://#{ip}").and_return(xen_api)

    subject.class.create(ip, username, password)
  end
end
