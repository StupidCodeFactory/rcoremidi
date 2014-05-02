# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rake, task: :default  do
  watch(%r{^some_files/.+$})
end

guard :rspec, cmd: "bundle exec rspec", all_on_start: true do
  watch(%r{lib/rcoremidi/rcoremidi.bundle}) { |m| "spec/ext/"}
  watch(%r{lib/(.+).rb}) { |m| "spec/#{m[1]}_spec.rb"}
end
