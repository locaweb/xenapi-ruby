require 'openssl'

module XenAPI

  class Error < RuntimeError
  end
  
  class ConnectionError < Error
  end
  
  class AuthenticationError < Error
  end
  
  class ExpirationError < Error
  end
  
  class TimeoutError < Error
  end
  
  class UnauthenticatedClient < Error
    def initialize(message = "Client needs to be authenticated first")
      super
    end
  end

  class NotMasterError < Error
		attr_accessor :master_ip

  	def initialize(message)
  	  super
			@master_ip = (/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/).match(message)[0]
  	end
  end
  
  module ErrorFactory
	  
	  API_ERRORS = {
	    "SESSION_AUTHENTICATION_FAILED" => AuthenticationError,
	    "HOST_IS_SLAVE" => NotMasterError,
	    "HOST_STILL_BOOTING" => ConnectionError
	  }
	  
	  TRANSLATIONS = {
	    EOFError => ExpirationError,
	    OpenSSL::SSL::SSLError => ExpirationError,
	    Errno::EHOSTUNREACH => ConnectionError,
	    Errno::ECONNREFUSED => ConnectionError,
	    Errno::EPIPE => ConnectionError,
	    Timeout::Error => TimeoutError
	  }
	  
	  def create(*args)
	    key = args[0]
	    message = args.join(": ")
	    error_class = API_ERRORS[key]
	    
	    return error_class.new message if error_class
	    Error.new message
    end
	  
		def wrap(error)
			return error if error.is_a? Error
			
			error_class = TRANSLATIONS[error.class]
			return error_class.new error.to_s if error_class
			Error.new "<#{error.class}> #{error}"
		end

    module_function :create, :wrap
	end
end
