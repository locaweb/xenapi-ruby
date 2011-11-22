module XenAPI
  module VirtualMachine
    def vm_ref(uuid)
      self.VM.get_by_uuid(uuid)
    end

    def vm_record(ref)
      self.VM.get_record(ref)
    end

    def vm_clone(ref_to_clone, name)
      self.VM.clone(ref_to_clone, name)
    end

    def tools_outdated?(ref)
      guest_ref = self.VM.get_guest_metrics(ref)
      guest_ref == "OpaqueRef:NULL" || !self.VM_guest_metrics.get_PV_drivers_up_to_date(guest_ref)
    rescue Exception
      false
    end

    def vbds(ref, opts = {})
      vm_vbds_refs = self.VM.get_record(ref)["VBDs"]

      vm_vbds_refs.inject({}) do |disks, vm_vbd_ref|
        vm_vbd_record = self.VBD.get_record(vm_vbd_ref)

        disks[vm_vbd_ref] = vm_vbd_record if opts[:include_cd] || vm_vbd_record["type"] == "Disk"
        disks
      end
    rescue => e
      {}
    end

    def hdd_physical_utilisation(vm_ref)
      vbds(vm_ref).values.inject(0) do |disk_size, vbd_record|
        disk_size += self.VDI.get_physical_utilisation(vbd_record['VDI']).to_i
      end / (1024**3) # in GB
    end

    def hdd_size(vm_ref)
      vbds(vm_ref).values.inject(0) do |disk_size, vbd_record|
        disk_size += self.VDI.get_virtual_size(vbd_record['VDI']).to_i
      end / (1024**3) # in GB
    end

    def vm_main_vif_ref(ref)
      self.VM.get_VIFs(ref).find do |vif_ref|
        self.VIF.get_device(vif_ref) == "0"
      end
    end

    def vifs(ref)
      vif_refs = self.VM.get_VIFs(ref)
      vif_refs.inject({}) do |interfaces, vif_ref|
        network_ref = self.VIF.get_network(vif_ref)
        network_label = self.network.get_name_label(network_ref)
        interfaces[vif_ref] = self.VIF.get_record(vif_ref).merge("network_label" => network_label)

        interfaces
      end
    rescue
      {}
    end

    def remove_disks_from_hypervisor(vm_ref)
      vbds(vm_ref).each_value do |vbd_record|
        self.VDI.destroy(vbd_record['VDI'])
      end
    end

    def next_disk_number(vm_ref)
      device_map = {}

      vbds(vm_ref, :include_cd => true).each_pair do |vbd_ref, vbd_record|
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

    def cd_ref(vm_ref)
      vbds(vm_ref, :include_cd => true).each_pair do |ref, record|
        return ref if record["type"] == "CD"
      end
      nil
    end

    def insert_iso_cd(cd_ref, iso_ref)
      self.VBD.set_bootable(cd_ref, false)
      self.VBD.insert(cd_ref, iso_ref)
      true
    end

    def master_address
      pool_ref = self.pool.get_all.first
      master_ref = self.pool.get_master pool_ref
      self.host.get_address master_ref
    end

    def configure_network_interfaces_on(vm_ref)
      log_activity(:debug, "Setting up network interfaces")
      vif_refs = self.VM.get_VIFs(vm_ref)
      raise "Template doesn't have any network interfaces" if vif_refs.nil? || vif_refs.empty?
      vif_record = self.VIF.get_record(vm_main_vif_ref(vm_ref))
      self.mac = vif_record["MAC"]
    end

    def exists_on_hypervisor?(uuid)
      self.VM.get_by_uuid(uuid)
      true
    rescue XenAPI::Error
      false
    end

    def set_memory_size(vm_ref, memory_in_MB)
      memory_in_MB = memory_in_MB.to_s
      self.VM.set_memory_limits(vm_ref, memory_in_MB, memory_in_MB, memory_in_MB, memory_in_MB)
      self
    end

    def created_vifs(vm_ref)
      vifs(vm_ref).to_a.inject({}) do |map, pair|
        map[pair.last["network_label"]] = pair.first
        map
      end
    end

    def set_cpus_size(vm_ref, cpus)
      cpus = cpus.to_s
      max_cpus = self.VM.get_VCPUs_max(vm_ref).to_i

      # On upgrade, we want set VCPUS max before VCPUS at startup and vice versa
      if cpus.to_i > max_cpus
        self.VM.set_VCPUs_max(vm_ref, cpus)
        self.VM.set_VCPUs_at_startup(vm_ref, cpus)
      else
        self.VM.set_VCPUs_at_startup(vm_ref, cpus)
        self.VM.set_VCPUs_max(vm_ref, cpus)
      end

      self
    end

    def adjust_vcpu_priority(vm_ref, priority)
      log_activity(:debug, "Setting up priority")
      parameters = self.VM.get_VCPUs_params(vm_ref)
      parameters["weight"] = priority.to_s
      self.VM.set_VCPUs_params(vm_ref, parameters)

      self
    end

    def import(file_path, storage_uuid = nil)
      file = File.open(file_path, "rb")

      session_ref = self.key
      storage_ref = storage_uuid ? self.SR.get_by_uuid(storage_uuid) : ""
      task_ref = self.task.create "import vm #{file_path}", "importat job"

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

      task_rec = self.task.get_record task_ref
      vm_ref = task_rec["result"].gsub(/<.*?>/, "")
      self.VM.get_uuid(vm_ref)
    ensure
      file.close rescue nil
      self.task.destroy(task_ref) rescue nil
    end

    def export(vm_uuid, options = {})
      options = {:to => "/tmp/export_file"}.merge(options)
      file = File.open(options[:to], "wb")
      session_ref = self.key
      task_ref = self.task.create "export vm #{vm_uuid}", "export job"

      path = "/export?session_id=#{session_ref}&task_id=#{task_ref}&ref=#{self.vm_ref(vm_uuid)}"
      uri  = URI.parse "http://#{master_address}#{path}"

      Net::HTTP.get_response(uri) do |res|
        res.read_body {|chunk| file.write chunk }
      end

      options[:to]
    ensure
      file.close rescue nil
      self.task.destroy(task_ref) rescue nil
    end
  end
end
