# -*- encoding: utf-8 -*-
module XenAPI
  module Network
    def network_name_label(name_label)
      self.network.get_by_name_label(name_label)
    end
  end
end
