module XenAPI
  class Dispatcher
    undef_method :clone
    
    def initialize(proxy, &error_callback)
      @proxy = adjust_proxy_methods!(proxy)
      @error_callback = error_callback
    end

    def method_missing(name, *args)
      begin
        response = @proxy.send(name, *args)
        raise XenAPI::ErrorFactory.create(*response['ErrorDescription']) unless response['Status'] == 'Success'
        response['Value']
      rescue Exception => exc
        error = XenAPI::ErrorFactory.wrap(exc)
        if @error_callback
          @error_callback.call(error) do |new_session|
            prefix = @proxy.prefix.delete(".").to_sym
            dispatcher = new_session.send(prefix)
            dispatcher.send(name, *args)
          end
        else
          raise error
        end
      end
    end
    
    private
      def adjust_proxy_methods!(proxy)
        proxy.instance_eval do
          def clone(*args)
            method_missing(:clone, *args)
          end
          def copy(*args)
            method_missing(:copy, *args)
          end

          def prefix
            @prefix
          end
        end

        proxy
      end

  end
end
