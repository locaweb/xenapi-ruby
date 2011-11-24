# -*- encoding: utf-8 -*-
module XenAPI
  module Vdb
    def create_VBD_for(vm_ref, disk_uuid, disk_number)
      self.VBD.create({
        :VM => vm_ref,
        :VDI => self.on_hypervisor.VDI.get_by_uuid(disk_uuid),
        :userdevice => disk_number.to_s,
        :bootable => false,
        :mode => "RW",
        :type => "Disk",
        :unpluggable => false,
        :empty => false,
        :other_config => {},
        :qos_algorithm_type => "",
        :qos_algorithm_params => {}
      })
    end
  end
end
