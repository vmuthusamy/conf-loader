require 'bundler'
require 'conf/config_loader'
require 'pp'
Bundler.require(:default)

class Loader
  # provides the entry point into the application
  # delegates the work to ConfLoader class which
  # parses the file from the specified path and
  # returns a config file which can be queried
  def self.load_config(file_path, overrides = [])
    if file_path.nil? or not File.exist?(file_path)
      raise 'Please specify a valid file path: ' << file_path
    end
    ConfLoader.new(file_path, overrides).process
  end
end

#uncomment to run this class manually

CONFIG= Loader.load_config('srv/settings.conf',['ubuntu','production'])

#pp CONFIG
