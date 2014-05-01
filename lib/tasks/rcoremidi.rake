namespace :rcoremidi do
  desc "List available midi end points"
  task :list do
    RCoreMidi::Device.all
  end
end
