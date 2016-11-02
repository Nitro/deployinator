
BASE_TIME = Time.new(2016, 10, 25)

module Deployinator
  class Orchestrator

    def initialize(@base_url : String, @project : String, @output : StatusOutput); end

    def deploy
      filename = "projects/#{@project}.yaml"
      deploy_request = prepare_payload(filename)

      post_deploy(deploy_request)

      job_status = follow_status(deploy_request)
      @output.print_job_status(job_status)

      history = get_completion_status(deploy_request)
      @output.print_final_status(history)

      history.deploy_result.deploy_state == "SUCCEEDED"
    end

    def prepare_payload(filename)
      deploy_request = DeployWrapper.from_yaml(File.read(filename))
      deploy_request.deploy.id = (Time.now.epoch - BASE_TIME.epoch).to_s
      deploy_request
    end

    def post_deploy(deploy_request)
      @output.print_deploy_request(deploy_request)
      with_retries(3) do
        JsonClient.post(@base_url, "/singularity/api/deploys", deploy_request)
      end
    end

    def pending_deploy(deploy_request)
      begin
        deployments = JsonClient.new(Array(DeploymentStatus)).get(
          @base_url, "/singularity/api/deploys/pending"
        )
      rescue e : JsonClient::InvalidResponse
        puts "Error in response: #{e.inspect}"
        return {:bad, nil}
      end

      deployments = deployments.select do |d|
        d.deploy_marker["deployId"] == deploy_request.deploy.id
      end

      return {:good, nil} if deployments.empty?

      {:good, deployments.first}
    end

    def follow_status(deploy_request)
      @output.announce_deploy

      success = true
      loop do
        status, deploy = pending_deploy(deploy_request)
        case
          when status == :bad then return (success = false)
          when {status, deploy} == {:good, nil} then return (success = true)
          when deploy.nil? then return (success = false)
          else
        end

        # Since we know we're not a Nil, cast to DeploymentStatus
        this_deploy = deploy.as(DeploymentStatus)

        @output.print_deploy_status(this_deploy)
        return (success = false) unless this_deploy.deploy_progress.failed_deploy_tasks.empty?

        sleep 1
      end

      @output.finalize_deploy
      success
    end

    def get_completion_status(deploy_request)
      deploy = deploy_request.deploy
      JsonClient.new(DeploymentHistory).get(@base_url,
        "/singularity/api/history/request/#{deploy.request_id}/deploy/#{deploy.id}"
      )
    end

    def with_retries(count, &block)
      error = nil
      result = nil

      1.upto(count) do |i|
        begin
          result = yield
          error = nil
          break
        rescue e : Exception
          puts "Retrying #{i} of #{count}".colorize(:yellow)
          error = e
        end
      end

      raise error unless error.nil?
      result
    end
  end
end
