#!/usr/local/bin/ruby
require 'json'
require 'fileutils'

load '/wikk/etc/wikk.conf' unless defined? WIKK_CONF
require_relative "#{RLIB}/net/network_node_def.rb" # Should pull this from the database, so we don't maintain a separate copy.
require_relative "#{RLIB}/net/save_routes.rb"

@conf = JSON.parse(File.read('/wikk/etc/net/gen_routes.json'))
@nodes = Nodes.new(conf: @conf['node_file'])

# Mkdir for the routes shell scripts. Relative to script directory, unless full path is given.
routes_dir = @conf['route_dir']
FileUtils.mkdir_p(routes_dir)

# For each node in the network, output a route script
@nodes.each do |node_name, node_details|
  Save_Routes.open(routes_dir: routes_dir, node_name: node_name, target: node_details[:node_type]) do |sr|
    sr.save_routes(routes: node_details[:final_routes])
    sr.save_routes(routes: node_details[:distribution_routes])
  end
end
