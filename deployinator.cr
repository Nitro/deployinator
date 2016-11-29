require "time"
require "option_parser"
require "./src/deployinator"

singularity_base_url = "http://dev-singularity-fluffy-cancel.uw2.nitro.us:7099"
mesos_base_url = "http://dev-singularity-implicit-county.uw2.nitro.us:5050"
project  = ""

OptionParser.parse! do |parser|
  parser.banner = "Usage: deployinator [arguments]"
  parser.on("-u URL", "--url=URL", "The Singularity base URL to use")   { |u| singularity_base_url = u }
  parser.on("-m URL", "--mesos=URL", "The Mesos base URL to use")       { |u| mesos_base_url = u }
  parser.on("-p PROJECT", "--project=PROJECT", "The project to deploy") { |p| project = p }
  parser.on("-h", "--help", "Show this help")                           { puts parser; exit }
end

if project.empty?
  abort "You must provide a project name!"
end

deployer = Deployinator::Orchestrator.new(
  base_url: singularity_base_url,
  mesos_base_url: mesos_base_url,
  project: project,
  output: Deployinator::TerminalStatusOutput.new
)

exit 1 unless deployer.deploy
