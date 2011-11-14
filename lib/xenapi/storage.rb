module XenAPI
  module Storage
    def ref
      on_hypervisor.SR.get_by_uuid(self.uuid)
    end
  end
end
