require "colorize"

require "./data"
require "./http"

class Deployinator

  def initialize(@base_url : String, @project : String); end

  def deploy
    filename = "projects/#{@project}.yaml"
    deploy_request = prepare_payload(filename)

    result = post_deploy(deploy_request)
    raise "Invalid response: #{result.inspect}" unless valid_response?(result)

    job_status = follow_status(deploy_request)
    handle_final_status(job_status)
  end

  def valid_response?(result)
    result.status_code == 200 && result.headers["Content-Type"] == "application/json"
  end

  def print_hr(extra_cr=true)
    puts ("-"*40).colorize(:blue)
    puts "\n" if extra_cr
  end

  def out(str)
    puts str.colorize(:green)
  end

  def handle_final_status(success)
    puts ("-"*40).colorize(:blue)
    puts "\nERROR, job failure!".colorize(:red) unless success
    puts "\nDone!".colorize(:green) if success
  end

  def prepare_payload(filename)
    deploy_request = DeployWrapper.from_yaml(File.read(filename))
    deploy_request.deploy.id = (Time.now.epoch - BASE_TIME.epoch).to_s
    deploy_request
  end

  def post_deploy(deploy_request)
    payload = deploy_request.to_json

    print_hr(extra_cr: false)
    out "[ Submitting: #{deploy_request.deploy.request_id}"
    out "[ Request Id: #{deploy_request.deploy.id}"
    out "[ At: #{Time.now.to_s("%Y-%m-%d %H:%M:%S")}"
    print_hr

    result = http_client(@base_url) do |client|
      client.post("/singularity/api/deploys", body: payload)
    end

    unless result.status_code == 200
      abort "Something went wrong!\n#{result.inspect}"
    end

    return result
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
    puts "Deploying! -----------------------------".colorize(:blue)

    success = true
    loop do
      status, deploy = pending_deploy(deploy_request)
      return (success = false) if status == :bad
      return (success = true) if status == :good && deploy.nil?

      # Since we know we're not a Symbol or Nil, cast to DeploymentStatus
      this_deploy = deploy as DeploymentStatus

      out(" * Targetting: #{this_deploy.deploy_progress.target_active_instances} " +
        "instances - #{this_deploy.current_deploy_state}")

      return (success = false) unless this_deploy.deploy_progress.failed_deploy_tasks.empty?

      sleep 1
    end

    print_hr

    success
  end
end
