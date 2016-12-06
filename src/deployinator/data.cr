require "json"
require "yaml"

# Macro to reduce duplication in mapping values to both
# JSON and YAML since we read YAML and send JSON.
macro translation_map(values)
  JSON.mapping({{ values }})
  YAML.mapping({{ values }})
end

module Deployinator
  struct DockerInfo
    translation_map({
      image: String,
      network: String,
      port_mappings: {
        type: Array(Hash(String, String | Int32)),
        key: "portMappings",
        nilable: true
      },
      docker_parameters: {
        type: Array(Hash(String, String | Int32)),
        key: "dockerParameters",
        nilable: true
      },
      force_pull_image: {
        type: Bool,
        key: "forcePullImage",
        nilable: true
      }
    })
  end

  struct ContainerInfo
    translation_map({
      type: String,
      docker: DockerInfo,
      volumes: {
        type: Array(Hash(String, String)),
        nilable: true
      }
    })
  end

  struct Deployment
    translation_map({
      request_id: { type: String, key: "requestId" },
      id: { type: String, nilable: true },
      container_info: { type: ContainerInfo, key: "containerInfo" },
      resources: Hash(String, Int32 | Float64),
      healthcheck_uri: { type: String, key: "healthcheckUri", nilable: true },
      deploy_health_timeout_seconds: { type: Int64, key: "deployHealthTimeoutSeconds", nilable: true },
      healthcheck_interval_seconds: { type: Int64, key: "healthcheckIntervalSeconds", nilable: true },
      healthcheck_timeout_seconds: { type: Int64, key: "healthcheckTimeoutSeconds", nilable: true },
      healthcheck_port_index: { type: Int32, key: "healthcheckPortIndex", nilable: true },
      healthcheck_max_retries: { type: Int32, key: "healthcheckMaxRetries", nilable: true },
      healthcheck_max_total_timeout_seconds: { type: Int64, key: "healthcheckMaxTotalTimeoutSeconds", nilable: true },

      deploy_instance_count_per_step: {
        type: Int32,
        nilable: true,
        key: "deployInstanceCountPerStep"
      },
      deploy_step_wait_time_ms: {
        type: Int32,
        nilable: true,
        key: "deployStepWaitTimeMs"
      },
      auto_advance_deploy_steps: {
        type: Bool,
        nilable: true,
        key: "autoAdvanceDeploySteps"
      },

      custom_executor_command: {
        key: "customExecutorCmd",
        type: String,
        nilable: true
      },

      env: { type: Hash(String, String), nilable: true }
    })
  end

  struct DeployWrapper
    translation_map({
      deploy: Deployment
    })
  end

  # [
  #   {
  #     "deployMarker": {
  #       "requestId": "nginx",
  #       "deployId": "144087",
  #       "timestamp": 1477494083979
  #     },
  #     "currentDeployState": "WAITING",
  #     "deployProgress": {
  #       "targetActiveInstances": 3,
  #       "deployInstanceCountPerStep": 3,
  #       "deployStepWaitTimeMs": 0,
  #       "stepComplete": false,
  #       "autoAdvanceDeploySteps": true,
  #       "failedDeployTasks": [],
  #       "timestamp": 1477494083979
  #     }
  #   }
  # ]

  struct DeploymentStatus
    translation_map({
      deploy_marker: {
        type: Hash(String, String | Int32),
        key: "deployMarker"
      },
      current_deploy_state: {
        type: String,
        key: "currentDeployState"
      },
      deploy_progress: {
        type: DeploymentProgress,
        key: "deployProgress"
      }
    })
  end

  struct DeploymentProgress
    translation_map({
      target_active_instances: {
        type: Int32,
        key: "targetActiveInstances"
      },
      deploy_instance_count_per_step: {
        type: Int32,
        key: "deployInstanceCountPerStep"
      },
      deploy_step_wait_time_ms: {
        type: Int64,
        key: "deployStepWaitTimeMs"
      },
      step_complete: {
        type: Bool,
        key: "stepComplete"
      },
      auto_advance_deploy_steps: {
        type: Bool,
        key: "autoAdvanceDeploySteps"
      },
      failed_deploy_tasks: {
        type: Array(String),
        key: "failedDeployTasks"
      },
      timestamp: {
        type: Int32,
        key: "timestamp"
      }
    })
  end

  struct DeploymentHistory
    translation_map({
      deploy_result: {
        type: DeploymentResult,
        key: "deployResult"
      }
    })
  end

  struct DeploymentResult
    translation_map({
      deploy_state: { type: String, key: "deployState" },
      message: { type: String, nilable: true },
      deploy_failures: {
        type: Array(DeploymentFailure),
        key: "deployFailures",
        nilable: true
      },
      timestamp: Int32
    })
  end

  struct DeploymentFailure
    translation_map({
      reason: String
    })
  end

  #{
  #  "deployResult": {
  #    "deployState": "OVERDUE",
  #    "message": "Only 0 of 3 tasks could be launched for deploy, there may not be enough resources to launch the remaining tasks",
  #    "deployFailures": [],
  #    "timestamp": 1477664964739
  #  },
end
