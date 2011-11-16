# -*- encoding: utf-8 -*-
module XenAPI
  module Vdb
    def create_VDB_for(disk_object)
      self.VBD.create({
        :VM => disk.virtual_machine.ref,
        :VDI => disk.ref,
        :userdevice => disk.number.to_s,
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
