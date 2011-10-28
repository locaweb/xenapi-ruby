module XenAPI
  module VirtualMachine
    def name_label
      hypervisor_session.VM.get_name_label(self.ref)
    end

    def tools_outdated?
      guest_ref = hypervisor_session.VM.get_guest_metrics(ref)
      guest_ref == "OpaqueRef:NULL" || !hypervisor_session.VM_guest_metrics.get_PV_drivers_up_to_date(guest_ref)
    rescue Exception
      false
    end

    def hdd_physical_utilisation
      vbds.values.inject(0) do |disk_size, vbd_record|
        disk_size += hypervisor_session.VDI.get_physical_utilisation(vbd_record['VDI']).to_i
      end / (1024**3) # in GB
    end

    def hdd_size
      vbds.values.inject(0) do |disk_size, vbd_record|
        disk_size += hypervisor_session.VDI.get_virtual_size(vbd_record['VDI']).to_i
      end / (1024**3) # in GB
    end

    def set_hdd_size
      additional_hdd_size = hdd - hdd_size
      raise "Cannot downgrade disk amount (in #{additional_hdd_size} GB)" if additional_hdd_size < 0

      disk = additional_disks.last
      raise "Additional disk not found in database, please update" if disk.nil?
      disk.update_on_hypervisor(disk.size + additional_hdd_size)

      self
    end

    def vdi_uuid(vdi_ref)
      hypervisor_session.VDI.get_uuid(vdi_ref)
    end

    def host_name
      host_ref = hypervisor_session.VM.get_resident_on(ref)
      host_name = hypervisor_session.host.get_name_label(host_ref)
    rescue
      nil
    end

    def ref
      hypervisor_session.VM.get_by_uuid(self.uuid)
    end

    def remove_disks_from_hypervisor
      vbds.each_value do |vbd_record|
        hypervisor_session.VDI.destroy(vbd_record['VDI'])
      end
    end

    def remove_machine_from_hypervisor
      hypervisor_session.VM.destroy(self.ref)
    end

    def vbds(opts = {})
      vm_vbds_refs = hypervisor_session.VM.get_record(self.ref)["VBDs"]

      vm_vbds_refs.inject({}) do |disks, vm_vbd_ref|
        vm_vbd_record = hypervisor_session.VBD.get_record(vm_vbd_ref)

        disks[vm_vbd_ref] = vm_vbd_record if opts[:include_cd] || vm_vbd_record["type"] == "Disk"
        disks
      end
    rescue => e
      {}
    end

    def main_vif_ref
      hypervisor_session.VM.get_VIFs(self.ref).find do |vif_ref|
        hypervisor_session.VIF.get_device(vif_ref) == "0"
      end
    end

    def next_disk_number
      device_map = {}

      vbds(:include_cd => true).each_pair do |vbd_ref, vbd_record|
        userdevice = vbd_record["userdevice"].to_i
        device_map[userdevice] = vbd_ref
      end

      disk_number = 0

      device_map.size.times do
        break if device_map[disk_number].nil?
        disk_number +=1
      end

      disk_number
    end

    def exists_on_hypervisor?(pool)
      return false if pool.nil?
      hypervisor_session.VM.get_by_uuid(uuid)
      true
    rescue XenAPI::Error
      false
    end

    def set_cpus_size(cpus)
      cpus = cpus.to_s
      max_cpus = hypervisor_session.VM.get_VCPUs_max(ref).to_i

      # On upgrade, we want set VCPUS max before VCPUS at startup and vice versa
      if cpus.to_i > max_cpus
        hypervisor_session.VM.set_VCPUs_max(ref, cpus)
        hypervisor_session.VM.set_VCPUs_at_startup(ref, cpus)
      else
        hypervisor_session.VM.set_VCPUs_at_startup(ref, cpus)
        hypervisor_session.VM.set_VCPUs_max(ref, cpus)
      end

      self
    end

    def set_memory_size(memory_in_MB)
      memory_in_MB = memory_in_MB.to_s
      hypervisor_session.VM.set_memory_limits(ref, memory_in_MB, memory_in_MB, memory_in_MB, memory_in_MB)
      self
    end

    def insert_iso_cd(iso)
      hypervisor_session.VBD.set_bootable(cd_ref, false)
      hypervisor_session.VBD.insert(cd_ref, iso.iso_ref(self.pool))
      true
    end

    def cd_ref
      vbds(:include_cd => true).each_pair do |ref, record|
        return ref if record["type"] == "CD"
      end
      nil
    end

    def eject_iso_cd
      hypervisor_session.VBD.eject(cd_ref)
      hypervisor_session.VM.set_HVM_boot_policy(ref, "") if matrix_machine.paravirtualized?
      true
    end

    def cd_object
      hypervisor_session.VBD.get_record(cd_ref)
    end

    def inserted_iso_cd?
      cd_object["allowed_operations"].include?("eject")
    rescue
      false
    end

    def adjust_vcpu_priority(priority)
      log_activity(:debug, "Setting up priority")
      parameters = hypervisor_session.VM.get_VCPUs_params(ref)
      parameters["weight"] = priority.to_s
      hypervisor_session.VM.set_VCPUs_params(ref, parameters)

      self
    end

    def tagged_with_deactivated?(vm_ref = nil)
      vm_ref = self.ref if vm_ref.nil?
      hypervisor_session.VM.get_tags(vm_ref).include?("DEACTIVATED")
    rescue XenAPI::Error
      false
    end

    def vifs
      vif_refs = hypervisor_session.VM.get_VIFs(self.ref)
      vif_refs.inject({}) do |interfaces, vif_ref|
        network_ref = hypervisor_session.VIF.get_network(vif_ref)
        network_label = hypervisor_session.network.get_name_label(network_ref)
        interfaces[vif_ref] = hypervisor_session.VIF.get_record(vif_ref).merge("network_label" => network_label)

        interfaces
      end
    rescue
      {}
    end

    def created_vifs
      vifs.to_a.inject({}) do |map, pair|
        map[pair.last["network_label"]] = pair.first
        map
      end
    end

    def configure_network_interfaces_on(vm_clone)
      log_activity(:debug, "Setting up network interfaces")
      vif_refs = hypervisor_session.VM.get_VIFs(vm_clone)
      raise "Template doesn't have any network interfaces" if vif_refs.nil? || vif_refs.empty?
      vif_record = hypervisor_session.VIF.get_record(main_vif_ref)
      self.mac = vif_record["MAC"]
    end

    def export(options = {})
      options = {:to => "/tmp/export_file"}.merge(options)
      file = File.open(options[:to], "wb")
      session_ref = hypervisor_session.key
      task_ref = hypervisor_session.task.create "export vm #{self.uuid}", "export job"

      path = "/export?session_id=#{session_ref}&task_id=#{task_ref}&ref=#{self.ref}"
      uri  = URI.parse "http://#{master_address}#{path}"

      Net::HTTP.get_response(uri) do |res|
        res.read_body {|chunk| file.write chunk }
      end

      options[:to]
    ensure
      file.close rescue nil
      hypervisor_session.task.destroy(task_ref) rescue nil
    end

    def import(file_path, storage_uuid = nil)
      file = File.open(file_path, "rb")

      session_ref = hypervisor_session.key
      storage_ref = storage_uuid ? hypervisor_session.SR.get_by_uuid(storage_uuid) : ""
      task_ref = hypervisor_session.task.create "import vm #{file_path}", "importat job"

      path = "/import?session_id=#{session_ref}&task_id=#{task_ref}&sr_id=#{storage_ref}"

      http = Net::HTTP.new(master_address, 80)
      request = Net::HTTP::Put.new(path, {})
      request.body_stream = file
      request.content_length = file.size
      begin
        http.request(request)
      rescue Errno::ECONNRESET
        logger.warn "VM import did a connection reset, but does not indicate an error"
      rescue Timeout::Error
        error = "Could not import VM due to timeout error: check if your image is valid"
        logger.error error
        raise error
      end

      task_rec = pool.hypervisor_session.task.get_record task_ref
      vm_ref = task_rec["result"].gsub(/<.*?>/, "")
      hypervisor_session.VM.get_uuid(vm_ref)
    ensure
      file.close rescue nil
      hypervisor_session.task.destroy(task_ref) rescue nil
    end

    def inserted_iso_name
      return nil unless inserted_iso_cd?

      iso_ref = cd_object["VDI"]
      hypervisor_session.VDI.get_record(iso_ref)["name_label"]
    rescue => e
      eject_iso_cd
      raise e
    end

    def master_address
      pool_ref = hypervisor_session.pool.get_all.first
      master_ref = hypervisor_session.pool.get_master
      hypervisor_session.host.get_address master_ref
    end
  end
end
