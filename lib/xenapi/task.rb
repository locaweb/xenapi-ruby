# -*- encoding: utf-8 -*-
module XenAPI
  module Task
    def task_record(ref)
      self.task.get_record ref
    end

    def task_destroy(ref)
      self.task.destroy ref
    end

    def task_create(name, description="Task creation")
      self.task.create(name, description)
    end
  end
end
