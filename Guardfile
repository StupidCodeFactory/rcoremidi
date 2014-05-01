# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rspec, :task => [:clean, :compile] do
  watch(%r{ext/rcoremidi/*.c})
  watch(%r{lib/(.+).rb}) { |m| "spec/#{m[1]}_spec.rb"}
end
