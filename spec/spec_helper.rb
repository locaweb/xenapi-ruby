# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'xenapi-ruby'

::OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:verify_mode] = ::OpenSSL::SSL::VERIFY_NONE

# Requiring all support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include(Mock::XenAPIMockery)
end
