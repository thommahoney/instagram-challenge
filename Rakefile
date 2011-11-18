require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  puts e.message
  exit e.status_code
end
require 'rake'
require './image_unshredder.rb'

task :test do
  Dir['test_images/*'].each do |file|
    if file.match(/_shredded/).nil?
      puts "Skipping #{file}. Change the name to include \"_shredded\" if you want to unshred it."
      next
    end
    output_file = file.sub(/_shredded(\.[^\.]*)$/, '\1')
    puts "Unshredding #{file} to #{output_file}"
    ImageUnshredder.new(file, output_file)
  end
end

task :default => :test