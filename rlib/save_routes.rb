#save the node routes in files.
# @param fd [File] file we want to write to
# @param target [Symbol] One of :linux, :bsd, :zebra, :manual
# @param node_name [String] node we are saving routes for.
# @param routes [Array] routes for this node, so we can iterate through them. Individual routes are hashes.
#                      Route hash must have {:route => IPAddr, :network_name => String, :gw => String, :node_name => String, :local => Boolean}
def save_routes(fd:, target:, node_name:, routes:)
  if target == :linux || target == :bsd
    fd.puts "#!/bin/sh"
  end
  via_node = ''
  output = false
  
  fd.puts "##{node_name} #{Time.now.strftime("%Y-%m-%d %H:%M")} (#{target})" if target == :linux || target == :bsd || target == :manual
  fd.puts ";#{node_name} #{Time.now.strftime("%Y-%m-%d %H:%M")} (#{target})" if target == :zebra

  return if routes == nil
  res = routes.sort_by { |v| v[:route].to_i }
  res.each do |route|
    next if route[:local] #Don't need to output local interface routes.
    if route[:node_name] != via_node
      via_node = route[:node_name]
      output = true
    else
      output = false
    end
    if target == :linux
      if route[:route].to_s(with_bits: true) == '0.0.0.0/0'
        fd.puts "# Default (Will already be defined on router.)"
        fd.puts "# /sbin/route add default #{route[:gw]}"
      else
        fd.puts "# via #{via_node} <--------" if output
        fd.puts "# Network #{route[:network_name]}"
        fd.puts "/sbin/route add -net #{route[:route].to_string} netmask #{route[:route].mask_to_s} gw #{route[:gw]}"
      end
    elsif target == :bsd
      if route[:route].to_s(with_bits: true) == '0.0.0.0/0'
        fd.puts "# Default"
        fd.puts "/sbin/route add default #{route[:gw]}"
      else
        fd.puts "# via #{via_node} <--------" if output
        fd.puts "#   Network #{route[:network_name]}"
        fd.puts "/sbin/route add -net #{route[:route].to_string} -netmask #{route[:route].mask_to_s} #{route[:gw]}"
      end
    elsif target == :zebra  #config file format for WRT Routers.
      if route[:route].to_s(with_bits: true) == '0.0.0.0/0'
        fd.puts "; Default"
        fd.puts "ip route 0.0.0.0/0 #{route[:gw]}"
      else
        fd.puts "; via #{via_node} <--------" if output
        fd.puts ";   Network #{route[:network_name]}"
        fd.puts "ip route #{route[:route].to_s(with_bits: true)} #{route[:gw]}"
      end
    elsif target == :manual #config file format for WRT Routers.
      if route[:route].to_s(with_bits: true) == '0.0.0.0/0'
        fd.puts "# Default"
        fd.puts "#{route[:gw]}"
      else
        fd.puts "# via #{via_node} <--------" if output
        fd.puts "#   Network #{route[:network_name]}"
        fd.puts "#{route[:route].to_string} #{route[:route].mask_to_s} #{route[:gw]}"
      end
    end
  end
end
