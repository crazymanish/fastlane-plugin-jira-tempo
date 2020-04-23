describe Fastlane::Actions::JiraTempoAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The jira_tempo plugin is working!")

      Fastlane::Actions::JiraTempoAction.run(nil)
    end
  end
end
