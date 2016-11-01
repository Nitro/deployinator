require "./spec_helper"

Spec2.describe Deployinator::Orchestrator do
  let(output)   { Deployinator::StatusOutput.new }
  let(deployer) { Deployinator::Orchestrator.new(
      "http://example.com", "nginx", output
    )
  }

  describe "Building the payload" do
    let(payload) { deployer.prepare_payload("projects/nginx.yaml") }

    it "returns the right class" do
      expect(payload).to be_a(Deployinator::DeployWrapper)
    end

    it "contains the right content" do
      expect(payload.deploy.request_id).to eq("nginx")
    end

    it "generates a sane id" do
      expect(payload.deploy.id.nil?).to be_false
      expect(payload.deploy.id.as(String).to_i).to_be > 10000 < 1000000
    end
  end
end
