require "time"
require "option_parser"

require "./deployinator"
require "./output"

BASE_TIME = Time.new(2016, 10, 25)

base_url = "http://dev-singularity-sick-sing.uw2.nitro.us:7099"
project  = ""

OptionParser.parse! do |parser|
  parser.banner = "Usage: deploy [arguments]"
  parser.on("-u URL", "--url=URL", "The base URL to use") { |u| base_url = u }
  parser.on("-p PROJECT", "--project=PROJECT", "The project to deploy") { |p| project = p }
  parser.on("-h", "--help", "Show this help") { puts parser; exit }
end

if project.empty?
  abort "You must provide a project name!"
end

deployer = Deployinator.new(
  base_url: base_url,
  project: project,
  output: TerminalStatusOutput.new
)

exit 1 unless deployer.deploy
