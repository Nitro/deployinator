require "./json_client"
require "./data"

module Deployinator
  class MesosStatusManager
    def initialize(@base_url : String); end

    def fetch(request_id, task_id)
      inner_fetch.tasks.select do |task|
        task.id =~ /\A#{request_id}-#{task_id}/
      end
    end

    def inner_fetch
      JsonClient.new(MesosTaskWrapper).get(@base_url, "/master/tasks")
    rescue e : JsonClient::InvalidResponse
      STDERR.puts e.message
      raise e
    end
  end

  struct MesosTaskWrapper
    translation_map({
      tasks: Array(MesosTask)
    })
  end

  # Struct is not complete... some fields omitted
  struct MesosTask
    translation_map({
      id: String,
      name: String,
      framework_id: String,
      slave_id: String,
      statuses: Array(MesosTaskStatus)
    })

    def to_s
      state = @statuses.first.state
      "#{@id} - #{@name} - #{state} - #{@slave_id} (framework: #{@framework_id})"
    end
  end

  # Struct is not complete... some fields omitted
  struct MesosTaskStatus
    translation_map({
      state: String,
      timestamp: Float64
    })
  end
end

#{
#  "tasks": [
#    {
#      "id": "nginx-733215-1478086794375-1-dev_singularity_sick_sing-DEFAULT",
#      "name": "nginx",
#      "framework_id": "Singularity",
#      "executor_id": "",
#      "slave_id": "48647419-b03c-48f3-b938-2c2ad869eaab-S1",
#      "state": "TASK_RUNNING",
#      "resources": {
#        "disk": 0,
#        "mem": 128,
#        "gpus": 0,
#        "cpus": 0.1,
#        "ports": "[31900-31900]"
#      },
#      "statuses": [
#        {
#          "state": "TASK_RUNNING",
#          "timestamp": 1478086796.03858,
