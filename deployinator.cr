require "./data"
require "./http"

class Deployinator

  def initialize(@base_url : String, @project : String, @output : StatusOutput); end

  def deploy
    filename = "projects/#{@project}.yaml"
    deploy_request = prepare_payload(filename)

    result = post_deploy(deploy_request)
    raise "Invalid response: #{result.inspect}" unless valid_response?(result)

    job_status = follow_status(deploy_request)
    @output.print_job_status(job_status)

    history = get_completion_status(deploy_request)
    @output.print_final_status(history)

    history.deploy_result.deploy_state == "SUCCEEDED"
  end

  def valid_response?(result)
    result.status_code == 200 && result.headers["Content-Type"] == "application/json"
  end

  def prepare_payload(filename)
    deploy_request = DeployWrapper.from_yaml(File.read(filename))
    deploy_request.deploy.id = (Time.now.epoch - BASE_TIME.epoch).to_s
    deploy_request
  end

  def post_deploy(deploy_request)
    payload = deploy_request.to_json
    @output.print_deploy_request(deploy_request)

    result = http_client(@base_url) do |client|
      client.post("/singularity/api/deploys", body: payload)
    end

    unless result.status_code == 200
      abort "Something went wrong!\n#{result.inspect}"
    end

    result
  end

  def pending_deploy(deploy_request)
    result = http_client(@base_url) do |client|
      client.get("/singularity/api/deploys/pending")
    end

    unless valid_response?(result)
      puts "Error in response: #{result.inspect}"
      return [:bad, nil]
    end

    deployments = Array(DeploymentStatus).from_json(result.body).select do |d|
      d.deploy_marker["deployId"] == deploy_request.deploy.id
    end

    return [:good, nil] if deployments.empty?

    [:good, deployments.first]
  end

  def follow_status(deploy_request)
    @output.announce_deploy

    success = true
    loop do
      status, deploy = pending_deploy(deploy_request)
      return (success = false) if status == :bad
      return (success = true) if status == :good && deploy.nil?

      # Since we know we're not a Symbol or Nil, cast to DeploymentStatus
      this_deploy = deploy as DeploymentStatus

      @output.print_deploy_status(this_deploy)
      return (success = false) unless this_deploy.deploy_progress.failed_deploy_tasks.empty?

      sleep 1
    end

    @output.finalize_deploy
    success
  end

  def get_completion_status(deploy_request)
    deploy = deploy_request.deploy

    result = http_client(@base_url) do |client|
      client.get("/singularity/api/history/request/#{deploy.request_id}/deploy/#{deploy.id}")
    end

    unless valid_response?(result)
      raise "Error in response: #{result.inspect}"
    end

    DeploymentHistory.from_json(result.body)
  end
end
