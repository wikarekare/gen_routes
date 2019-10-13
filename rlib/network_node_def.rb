require_relative 'ipAddr_ext.rb'
require "wikk_json" #gem version
require_relative '../conf/nodes3.rb' #This is where the network nodes, and their interfaces are defined.

# holds a list of nodes on each network, and generates the routes needed to traverse the networks.
# Data is currently the conf/nodes.rb node definitions, but I will change this to get the data from the DB, which has all nodes and their interfaces.
class Nodes
  attr_accessor :networks_nodes
  attr_accessor :nodes
  attr_accessor :distribution
  
  def initialize
    @default_route = IPAddr.new('0.0.0.0/0')
    load_node_defs       #Load the node definitions
    distribution_defs    #Load the client network definitions
    gen_networks_nodes   #Generate hash of networks we know about, with an array of nodes on each named network.
    #debug_network_nodes
    gen_routes           #Generate the routes for each network, then generate the routes each node needs to reach all other networks.
    add_distribution_routes #Use the distribution defs to generate routes to each tower's client networks. 
  end
  
  #Iterater for nodes
  # @yield [Hash] Node_name, node_details
  def each
    @nodes.each { |n,v| yield n,v }
  end
    
  #This is an edge net if it is isolated, or has just one host on it.
  def edge_net?(network_name:)
    @networks_nodes[network_name] == nil || @networks_nodes[network_name].length == 1
  end
  
  #for each node, add routes from networks we are attached to.
  private def gen_node_routes
    @nodes.each do |node_name, node_details|
      #Cache network names directly attached to this host, so we can block loops.
      local_networks = []
      node_details[:interfaces].each do |interface|
        local_networks << interface[:network_name]
        interface[:route_hint].each do |rh|
          local_networks << rh[:network_name]
        end
      end
      
      #add in routes for this node.
      node_details[:final_routes] ||= []
      node_details[:interfaces].each do |interface|
        @network_routes[interface[:network_name]].each do |gw, routes|
          if gw != interface[:ipv4] #Don't want to record routes that go through us.
            routes.each do |route| 
              node_details[:final_routes] << route if ( route[:path] == nil || (! route[:path].include?(node_name))) && (! local_networks.include?(route[:network_name]))
            end
          else #Local interfaces.
            node_details[:final_routes] << {:network_name => interface[:network_name], :local => true, :node_name => node_name, :gw => gw, :interface_network_name => interface[:network_name],  :route => IPAddr.new(interface[:network]), :hop_count => 0, :path => [] }
          end
        end
      end
    end
  end
  
  private def debug_dump_final_node_routes
    puts "Node routes\n\n"
    @nodes.each do |node_name, node_details|
      puts node_name
      y = node_details[:final_routes].sort_by { |v| v[:route].to_i } #v[:local].to_s + v[:node_name] + v[:network_name] } # sort_by { |v| [v[:local], v[:network_name]]} Causes exception?
      y.each do |route|
        puts "  #{route}"
      end
      puts "*"*128
    end
  end

  #Walks recursively through the networks, from network_name.
  #Checks it hasn't looped back to a network it has already enumerated the routes for
  # @yield route [Hash] for each network found, with the route changed to be the first gateway on the path to this network.
  private def routes_i_have(network_name:, path: [], hop_count: 1)
    if @network_routes_next_hop[network_name] != nil #This network is connected to other networks.
      @network_routes_next_hop[network_name].each do |route| #For each route from this network.
        if (! path.include?(route[:node_name])) && network_name != route[:interface_network_name] #I.e. We have not found a path to this new network yet, and the new network isn't the current network.
          new_route = { :network_name => route[:network_name], :local => false, :node_name => route[:node_name], :gw => route[:gw], :interface_network_name => route[:interface_network_name],  :route=>route[:route], :hop_count => (route[:hop_count] == 2 ? hop_count + 1 : hop_count), :path => path + [route[:node_name]]}
          yield new_route 
        end
        if route[:network_name] != nil && (! path.include?(route[:node_name])) 
          #Recurse, to the network attached to the next node, as long as this network isn't point back to the last network.
          routes_i_have(network_name: route[:network_name], path: path + [route[:node_name]], hop_count: hop_count + 1) do |route2| #Result of yield above, after recursive call.
            new_route = { :network_name => route2[:network_name], :local => false, :node_name => route[:node_name], :gw => route[:gw], :interface_network_name => route[:interface_network_name],  :route=>route2[:route], :hop_count => route2[:hop_count], :path => route2[:path]}
            yield new_route
          end
        end
      end
    end
  end
  
  def path_contains_node_on_this_net(network:, path:)
    return if @networks_nodes[network] == nil
    @networks_nodes[network].each do |node_name|
      return true if path.include?(node_name)
    end
    return false
  end
  
  #Test to see if the new routes network already has a route through this gateway.
  #Deletes existing routes, if the new_route incorporates the existing one.
  # @return [Boolean] False, if the new_route already exists. True otherwise.
  def route_not_present?(network:, routes:, new_route:)
    break_next = false
    routes.reject! do |route|
      if break_next #Need this to be able to delete array element, and return. 'break true' does not delete the array element.
        break  
      elsif new_route[:route] == route[:route] && new_route[:hop_count] <  route[:hop_count] 
        break_next = true
        next true #Current route is already present, but with a higher hop_count, so delete it and add new one upon returning
      elsif route[:route].net_include?(new_route[:route]) #Route is already present, or a superset of the route.
        return false #Exit the loop, but don't delete the current one.
      else
        #Deletes this member if new one encompassed the route of the current one. This could apply to several route entries.
        new_route[:route].net_include?(route[:route])
      end
    end
    return true
  end
  
  #For each network we know of, record routes to all the other reachable networks.
  #Don't record routes to subnets of routes we already have.
  private def calculate_all_routes
    @network_routes = {} #Routes for each network
    #for each network we have next hop routes for, look for paths to other networks
    @network_routes_next_hop.each do |network_name, routes|
      #@networks_seen = [network_name]
      @network_routes[network_name] ||= {} #Within each network, routes per node
      default_route = { :hop_count => 1000, :gw => @default_route }
      routes_i_have(network_name: network_name, path: [], hop_count: 1) do |route|
        next if path_contains_node_on_this_net(network: network_name, path: route[:path][1..-1])
        @network_routes[network_name][route[:gw]] ||= []
        if route[:route] == @default_route
          if route[:hop_count] < default_route[:hop_count]
            default_route = route
          end
        else
          @network_routes[network_name][route[:gw]] << route if route_not_present?(network: network_name, routes: @network_routes[network_name][route[:gw]], new_route: route)
        end
      end
      if default_route[:gw] != @default_route
          @network_routes[network_name][default_route[:gw]] << default_route if route_not_present?(network: network_name, routes: @network_routes[network_name][default_route[:gw]], new_route: default_route)
      end
    end
  end
  
  private def debug_dump_network_routes 
    puts "Network routes\n\n"
    @network_routes.each do |network_name, gws|
      puts network_name
      gws.each do |gw, routes|
        puts "  :gw => #{gw}"
        routes.each do |route|
          puts "    #{route}"
        end
      end
      puts "*"*128
    end
  end

  #For each network, record the routes from each of the nodes on that network, so we know how to get to the next hop.
  #Gives us a way to find gateways from each network, onto adjacent networks, or with route hints, onto networks further away.
  private def calculate_next_hop
    @network_routes_next_hop = {}
    #for each of the networks we know of, fetch each nodes routes to build a next hop routing table
    @networks_nodes.each do |network_name, nodes|  
      @network_routes_next_hop[network_name] ||= []  #Holds routes for this network
      nodes.each do |node_name| 
        node_ip = "" #Need this because of scope rules.
        #Find this nodes IP on the network we are checking. Look at the nodes local route entries to see if the node is on this network.
        @nodes[node_name][:routes].each do |route| 
          node_ip = route[:gw] if network_name == route[:network_name] 
        end
        
        #Record routes from this node, as long as they aren't back to the network we are currently recording routes for. i.e. the interface network name isn't the current network name.
        @nodes[node_name][:routes].each do |route| #Routes for this node.
          @network_routes_next_hop[network_name] << { :network_name => route[:network_name], :local => false, :node_name => node_name, :gw => node_ip, :interface_network_name => route[:network_name], :route => route[:route], :hop_count => 1, :path => [] } if network_name != route[:network_name] 
        end
        
        #Record the routes hints as routes, as long as the interface is not onto the network we are currently recording routes for.
        @nodes[node_name][:interfaces].each do |i|
          if network_name != i[:network_name] && i[:route_hint] != nil
            i[:route_hint].each do |rh|
              @network_routes_next_hop[network_name] << { :network_name => rh[:network_name], :local => false, :node_name => node_name, :gw => node_ip, :interface_network_name => i[:network_name], :route => IPAddr.new(rh[:network]), :hop_count => 2, :path => []}
            end
          end
        end
      end
    end
  end
  
  private def debug_dump_next_hop_routes
    puts "Next Hop routes for each network\n\n"
    @network_routes_next_hop.each do |network_name, network_routes|
      print "#{network_name} => "
      network_routes.each do |route|
        puts "  #{route}"
      end
      puts
    end
    puts "*"*128
  end

  #For each node, record the routes for that nodes interfaces.
  #Provides a base, so we know which networks are directly attached to which nodes.
  private def gen_intial_node_routes
    #Add the base routes, which are those on directly connected interfaces.
    @nodes.each do |node_name, node_detail|
      node_detail[:interfaces].each do |i|
        node_detail[:routes] << {:network_name => i[:network_name], :local => true, :node_name => node_name, :gw => i[:ipv4], :interface_network_name => i[:network_name], :route => IPAddr.new(i[:network]), :hop_count => 0, :path => []} #Directly connected.
      end
    end
  end
  
  private def debug_dump_intial_node_routes
    puts "Initial node routes\n\n"
    @nodes.each do |node_name, node_details|
      puts node_name
      node_details[:routes].each do |route|
        puts "  #{route}"
      end
      puts "*"*128
    end
  end
      
  private def gen_routes
    gen_intial_node_routes
    #debug_dump_intial_node_routes
    calculate_next_hop
    #debug_dump_next_hop_routes
    calculate_all_routes #A route belongs to a node, and each node tells the adjacent nodes the routes it knows.
    #debug_dump_network_routes
    gen_node_routes
    #debug_dump_final_node_routes
  end

  #create a Hash of all networks defined in @nodes, with the nodes on each as an array of strings, per network.
  #This gives us the neighbouring nodes, so we can generate the next hop routes to the neighbouring networks.
  #nb. Should drop the network names as indexes and just use the IP address ranges of each network.
  private def gen_networks_nodes
    @networks_nodes = {}
    @networks_range = {}
    @local_networks = {}
    @nodes.each do |node_name, node_detail| #Hash of nodes
      node_detail[:interfaces].each do |i| #Array of Hashes.
        if @local_networks[ IPAddr.new( i[:network] ) ] == nil
          #Index the networks by IP Address
          @local_networks[ IPAddr.new( i[:network] ) ] = i[:network_name]
        end
        if @networks_nodes[ i[:network_name] ] == nil
          @networks_nodes[ i[:network_name] ] = [node_name]  #What nodes are on what networks
          @networks_range[ i[:network_name] ] = IPAddr.new( i[:network] )
          #ensure we haven't named the same network differently.
          if @local_networks[ IPAddr.new( i[:network] ) ] != i[:network_name]
            STDERR.puts "node[#{node_name}] network[#{i[:network_name]}] @local_networks[ #{ IPAddr.new( i[:network]) } ] != #{i[:network]}"
          end
        else
          @networks_nodes[ i[:network_name] ] << node_name
          #Ensure a node's network name matches the last IP Address assigned to that network name.
          if( @networks_range[ i[:network_name] ] != IPAddr.new( i[:network]) )
            STDERR.puts "node[#{node_name}] network[#{i[:network_name]}] #{@networks_range[i[:network_name].to_s]} != #{i[:network]}"
          end
        end
        #Ensure the IP address given to the node is in the network range of the node
        if ! @networks_range[ i[:network_name] ].include?(IPAddr.new(i[:ipv4]) )
          STDERR.puts "Nodes[#{node_name}] interface[#{i[:network_name]}] ipv4 #{i[:ipv4]} not in network #{@networks_range[i[:network_name].to_s]}"
        end
      end
    end
  end
  
  #Output each network, with the nodes that are on that network.
  private def debug_network_nodes
    @networks_nodes.each do |network, nodes|
      puts "#{network} #{nodes}"
    end
  end
  
  #needs a check to filter out routes to customers that are directly connected, rather than needing a route.
  def add_distribution_routes
    #'barn' => { :distribution => '192.168.204.0/24', :gw => '192.168.204.1', :sites => '10.4.0.0/16', :site_mask => 27, :site_size => 32, :count => 32},
    @distribution.each do |distribution_site_name, distribution_detail| 
      distribution_ip = IPAddr.new(distribution_detail[:distribution])
      site_ip_range = IPAddr.new(distribution_detail[:sites])
      @nodes[distribution_site_name] ||= {}                           #Make sure site has an entry
      @nodes[distribution_site_name][:distribution_routes] ||= []     #Somewhere to save the distribution routes.
      (1...distribution_detail[:count]).each do |c|
        interface_name = "#{distribution_site_name}-links"
        node_name = "#{distribution_site_name}-#{"%02d"%c}"
        gw = (distribution_ip + (c + 1)).to_string
        network = (site_ip_range + (c * distribution_detail[:site_size])).mask(distribution_detail[:site_mask])
        if( @local_networks[ network ] == nil )
          @nodes[distribution_site_name][:distribution_routes] << {:network_name => "#{node_name}-site", :local => false, :node_name => node_name, :gw => gw, :interface_network_name => interface_name,  :route => network, :hop_count => 1 }
        end
      end
    end
  end
end

