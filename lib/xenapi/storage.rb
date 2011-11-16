# -*- encoding: utf-8 -*-
module XenAPI
  module Storage
    def storage_ref(uuid)
      self.SR.get_by_uuid(uuid)
    end

    def storage_record(ref)
      @record ||= self.SR.get_record(ref)
    end

    def storage_name(uuid)
      self.SR.get_name_label storage_ref(uuid)
    end

    def all_storages
      self.SR.get_all
    end
  end
end
