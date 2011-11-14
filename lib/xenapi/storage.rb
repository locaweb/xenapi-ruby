# -*- encoding: utf-8 -*-
module XenAPI
  module Storage
    def storage_ref(uuid)
      on_hypervisor.SR.get_by_uuid(uuid)
    end

    def storage_record_by_ref(ref)
      on_hypervisor.SR.get_record ref
    end

    def storage_record(uuid)
      @record ||= on_hypervisor.SR.get_record storage_ref(uuid)
    end

    def storage_name(uuid)
      on_hypervisor.SR.get_name_label storage_ref(uuid)
    end

    def all_storages
      on_hypervisor.SR.get_all
    end
  end
end
