# -*- encoding: utf-8 -*-
module XenAPI
  module Vdi
    def create_VDI_for(vm_object, vdi_number)
      storage_ref = self.SR.get_by_uuid(self.uuid)

      vdi_ref = self.VDI.create({
        :name_label => "#{vm.name} DISK #{vdi_number}",
        :name_description => name_label,
        :SR => storage_ref,
        :virtual_size => (vm.hdd - vm.hdd_size).gigabytes.to_s,
        :type => "system",
        :sharable => false,
        :read_only => false,
        :other_config => {},
        :xenstore_data => {},
        :sm_config => {},
        :tags => []
      })

      self.VDI.get_record(vdi_ref)["uuid"]
    end
  end
end
