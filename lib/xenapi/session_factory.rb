# -*- coding: UTF-8 -*-
class SessionFactory
  ::OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:verify_mode] =
    ::OpenSSL::SSL::VERIFY_NONE

  def self.create(ip, username, password, &error_handling)
    session = XenAPI::Session.new("https://#{ip}", &error_handling)
    session.login_with_password(username, password)
  end
end
