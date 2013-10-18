namespace :spec do
  desc 'unit test'
  RSpec::Core::RakeTask.new :unit do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
  end
  desc 'integration test'
  RSpec::Core::RakeTask.new :integration do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
  end
end
