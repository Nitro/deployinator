require "colorize"

module Deployinator
  class StatusOutput
    def print_deploy_request(deploy_request); end
    def print_job_status(success); end
    def print_final_status(history); end
    def print_deploy_status(this_deploy); end
    def print_mesos_tasks(tasks); end
    def announce_deploy; end
    def finalize_deploy; end
  end

  class TerminalStatusOutput < StatusOutput
    def print_deploy_request(deploy_request)
      print_hr(extra_cr: false)
      out "[ Submitting: #{deploy_request.deploy.request_id}"
      out "[ Request Id: #{deploy_request.deploy.id}"
      out "[ At: #{Time.now.to_s("%F %H:%M:%S")}"
      print_hr
    end

    def print_job_status(success)
      print_hr(extra_cr: false)
      puts "\nERROR, job failure!".colorize(:red) unless success
      puts "\nDone".colorize(:green) if success
    end

    def print_final_status(history)
      deploy = history.deploy_result
      if deploy.deploy_state == "SUCCEEDED"
        puts "#{deploy.deploy_state}".colorize(:green)
        return
      end

      puts "#{deploy.deploy_state}: #{deploy.message}".colorize(:red)
    end

    def print_mesos_tasks(tasks)
      puts ("\nMesos Tasks " + "-"*68).colorize(:blue)

      tasks.each do |t|
        status = t.statuses.map { |s| s.state }.join(", ")
        color = if status =~ /TASK_RUNNING$/
          :green
        else
          :red
        end

        puts "#{t.id}: #{status.colorize(color)}"
      end
      print_hr
    end

    def announce_deploy
      puts ("Deploying! " + "-"*69).colorize(:blue)
    end

    def finalize_deploy
      print_hr
    end

    def print_deploy_status(this_deploy)
      out " * #{Time.new.to_s("%F %H:%M:%S")} - Targetting: #{this_deploy.deploy_progress.target_active_instances} " +
          "instances - #{this_deploy.current_deploy_state}"
    end

    def print_hr(extra_cr=true)
      puts ("-"*80).colorize(:blue)
      puts "\n" if extra_cr
    end

    def out(str)
      puts str.colorize(:green)
    end
  end
end
