require "./spec_helper"

Spec2.describe Deployinator::MesosStatusManager do
  describe "Fetching Mesos task status" do
    class StubbedMesosStatusManager < Deployinator::MesosStatusManager
      def inner_fetch
        Deployinator::MesosTaskWrapper.from_json(
          File.read(
            "spec/fixtures/mesos_status.json"
          )
        )
      end
    end

    subject { StubbedMesosStatusManager.new("http://example.com") }

    it "has three tasks for an existing request" do
      expect(subject.fetch("nginx", "733215").size).to eq(3)
    end

    it "knows the state of the tasks" do
      state = subject.fetch("nginx", "733215").first.statuses.map { |x| x.state }

      expect(state).to eq(["TASK_RUNNING"])
    end

    it "returns empty array for non-existent tasks" do
      expect(subject.fetch("nothing", "0").size).to eq(0)
    end
  end
end
