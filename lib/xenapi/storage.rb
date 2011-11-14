module XenAPI
  module Storage
    def ref
      on_hypervisor.SR.get_by_uuid(self.uuid)
    end

    def record
      @record ||= on_hypervisor.SR.get_record(ref)
    end
  end
end
