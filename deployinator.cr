require "time"
require "option_parser"
require "./src/deployinator"

base_url = "http://dev-singularity-sick-sing.uw2.nitro.us:7099"
project  = ""

OptionParser.parse! do |parser|
  parser.banner = "Usage: deployinator [arguments]"
  parser.on("-u URL", "--url=URL", "The base URL to use") { |u| base_url = u }
  parser.on("-p PROJECT", "--project=PROJECT", "The project to deploy") { |p| project = p }
  parser.on("-h", "--help", "Show this help") { puts parser; exit }
end

if project.empty?
  abort "You must provide a project name!"
end

deployer = Deployinator::Orchestrator.new(
  base_url: base_url,
  project: project,
  output: Deployinator::TerminalStatusOutput.new
)

exit 1 unless deployer.deploy
