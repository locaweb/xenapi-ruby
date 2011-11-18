module XenAPI
  require "xmlrpc/client"
  require 'xenapi/dispatcher'

  class Session
    extend XenAPI::VirtualMachine
    extend XenAPI::Vdi
    extend XenAPI::Vdb
    extend XenAPI::Storage
    extend XenAPI::Task
    extend XenAPI::Network

    attr_reader :key

    def initialize(uri, &block)
      @uri, @block = uri, block
    end

    def login_with_password(username, password, timeout = 1200)
      begin
        @client = XMLRPC::Client.new2(@uri, nil, timeout)
        @session = @client.proxy("session")

        response = @session.login_with_password(username, password)
        raise XenAPI::ErrorFactory.create(*response['ErrorDescription']) unless response['Status'] == 'Success'

        @key = response["Value"]

        #Let's check if it is a working master. It's a small pog due to xen not working as we would like
        self.pool.get_all

        self
      rescue Exception => exc
        error = XenAPI::ErrorFactory.wrap(exc)
        if @block
          # returns a new session
          @block.call(error)
        else
          raise error
        end
      end
    end

    def close
      @session.logout(@key)
    end

    # Avoiding method missing to get lost with Rake Task
    # (considering Xen tasks as Rake task (???)
    def task(*args)
      method_missing("task", *args)
    end

    def method_missing(name, *args)
      raise XenAPI::UnauthenticatedClient.new unless @key

      proxy = @client.proxy(name.to_s, @key, *args)
      Dispatcher.new(proxy, &@block)
    end
  end
end
