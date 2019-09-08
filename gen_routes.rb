#!/usr/local/bin/ruby 
require_relative 'rlib/network_node_def.rb' #Should pull this from the database, so we don't maintain a separate copy.
require_relative 'rlib/save_routes.rb'

  @nodes = Nodes.new

  @nodes.each do |node_name, node_details|
    File.open(__dir__+ "/node_routes/#{node_name}", "w+") do |fd|
      save_routes(fd: fd, target: node_details[:node_type], node_name: node_name, routes: node_details[:final_routes])
      save_routes(fd: fd, target: node_details[:node_type], node_name: node_name + " Distribution Routes", routes: node_details[:distribution_routes])
    end
  end

