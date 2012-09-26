# -*- coding: UTF-8 -*-
require 'timeout'

class HypervisorErrorHandler
  attr_accessor :pool, :error

  TIMEOUT = 30

  attr_accessor :logger

  def initialize(pool, error)
    self.pool = pool
    self.error = error
  end

  def handle_error
    logger.debug "Handling error on Hypervisor Connection: #{error.class} #{error}"
    if self.error.is_a? XenAPI::AuthenticationError
      send_critical_warning_for self.error
    elsif self.error.is_a? XenAPI::ExpirationError #EOFError
      reconnect_to_master
    elsif self.error.is_a? XenAPI::TimeoutError
      reconnect_to_master
    elsif self.error.is_a? XenAPI::NotMasterError
      connect_to_real_master_at self.error.master_ip
    else
      raise self.error
    end
  end

  private

  def reconnect_to_master
    master = pool.reload.master
    logger.debug "Reconnecting to master #{master.name}"
    connect_to master
  rescue Exception => exc
    logger.debug "Reconnect to master #{master.name} failed"
    check_first_slave_and_connect
  end

  def connect_to_real_master_at(master_ip)
    logger.debug "Connecting to real master at #{master_ip}"
    real_master = pool.master
    real_master.ip = master_ip

    connect_to real_master
  rescue Exception => exc
    logger.debug "Connection to real master failed"
    send_critical_warning_for exc
  end

  def send_critical_warning_for(exc)
    logger.fatal "Critical error handling Hypervisor session: #{exc}"
    raise exc
  end

  def connect_to(host)
    Timeout::timeout(TIMEOUT, XenAPI::TimeoutError) do
      SessionFactory.create(host.ip, host.username, host.password)
    end

    logger.debug "Connection to host #{host.name} is OK"
    change_to_master_on_db(host)
    XenAPI::HypervisorConnection.hypervisor_session!(host.reload)
  end
end
