# -*- encoding: utf-8 -*-
module XenAPI
  module Vdi
    def create_VDI_for(storage_ref, vm_object, vdi_number)
      vdi_ref = self.VDI.create({
        :name_label => "#{vm_object.name} DISK #{vdi_number}",
        :name_description => "#{vm_object.name} DISK #{vdi_number}",
        :SR => storage_ref,
        :virtual_size => (vm_object.hdd - vm_object.hdd_size).gigabytes.to_s,
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

    def vdi_ref(uuid)
      self.VDI.get_by_uuid(uuid)
    end

    def vdi_record(ref)
      self.VDI.get_record(ref)
    end

    def vdi_clone(ref)
      self.VDI.clone(vdi_ref)
    end

    def vdi_virtual_size(ref)
      self.VDI.get_virtual_size(ref).to_i/(1024**3)
    end

    def vdi_resize(ref, new_size)
      self.VDI.resize(ref, new_size.to_s)
    end

    def vdi_name_label=(ref, label)
      self.VDI.set_name_label(ref, label)
    end

    def vdi_name_label(label)
      self.VDI.get_by_name_label(label).first
    end

    def vdi_name_description=(ref, label)
      self.VDI.set_name_description(ref, label)
    end
  end
end
