require 'bundler'
require 'conf/config_loader'
require 'pp'
Bundler.require(:default)

# provides the entry point into the application
# delegates the work to ConfLoader class which
# parses the file from the specified path and
# returns a config file which can be queried
def load_config(file_path, overrides = [])

  if file_path.nil? or not File.exist?(file_path)
    raise 'Please specify a valid file path: ' << file_path
  end

  ConfLoader.new(file_path, overrides).process
end

CONFIG= load_config('../srv/settings.conf',['staging'])

pp CONFIG