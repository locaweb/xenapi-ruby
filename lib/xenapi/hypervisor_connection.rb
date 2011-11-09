# -*- coding: UTF-8 -*-
module XenAPI
  module HypervisorConnection
    class << self
      def hypervisor_session(host)
        sessions[host.ip] ||= hypervisor_session!(host)
      end

      def hypervisor_session!(host)
        Rails.logger.info "Connecting to hypervisor on #{host.ip} with user #{host.username}"
        session = SessionFactory.create(host.ip, host.username, host.password) do |error, &called_method|
          Rails.logger.error(error)
          session = HypervisorErrorHandler.new(host.pool, error).handle_error

          if called_method
            called_method.call(session)
          else
            session
          end
        end
      end

      def close_hypervisor_session!
        sessions.each do |host, session|
          begin
            session.close unless session.nil?
          rescue Exception => error
            Rails.logger.error("Error while trying to close connection to #{host}")
            Rails.logger.error(error)
          end
        end
        @sessions = {}
      end

     private
      def sessions
        @sessions ||= {}
      end
    end

    def hypervisor_session
      raise "Pool not found for #{self.inspect}" unless self.pool
      HypervisorConnection.hypervisor_session(self.pool.master)
    end
  end
end
