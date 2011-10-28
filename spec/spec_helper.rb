# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'xenapi-ruby'

::OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:verify_mode] = ::OpenSSL::SSL::VERIFY_NONE

RSpec.configure do |config|
end
