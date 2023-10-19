# save the node routes in files.
# @param fd [File] file we want to write to
# @param @target [Symbol] One of :linux, :bsd, :zebra, :manual
# @param @node_name [String] node we are saving routes for.
# @param routes [Array] routes for this node, so we can iterate through them. Individual routes are hashes.
#                      Route hash must have {:route => IPAddr, :network_name => String, :gw => String, :node_name => String, :local => Boolean}
class Save_Routes
  def initialize(fd:, node_name:, target: )
    @fd = fd
    @node_name = node_name
    @target = target
    @route_count = 0
  end

  def self.open( routes_dir:, node_name:, target: )
    File.open(routes_dir + '/' + node_name, 'w+') do |fd|
      c = self.new(fd: fd, node_name: node_name, target: target)
      c.create_route_command_leadin
      yield c
      c.create_route_command_trailer
    end
  end

  def create_route_command_leadin
    case @target
    when :linux, :bsd
      @fd.puts '#!/bin/bash'
      @fd.puts "# #{@node_name} #{Time.now.strftime('%Y-%m-%d %H:%M')} (#{@target})"
    when :json
      @fd.puts '{ ['
      @fd.puts "// #{@node_name} #{Time.now.strftime('%Y-%m-%d %H:%M')} (#{@target})"
    when :zebra
      @fd.puts "! #{@node_name} #{Time.now.strftime('%Y-%m-%d %H:%M')} (#{@target})"
    else
      @fd.puts "# #{@node_name} #{Time.now.strftime('%Y-%m-%d %H:%M')} (#{@target})"
    end
  end

  def create_route_command_trailer
    case @target
    when :json
      @fd.puts "\n] }"
    end
  end

  def create_route_command(route:, comment:)
    case @target
    when :ip
      if route[:route].to_s(with_bits: true) == '0.0.0.0/0'
        @fd.puts '# Default (Will already be defined on router.)'
        @fd.puts "# /sbin/route add default #{route[:gw]}"
      else
        @fd.puts "# #{comment}"
        @fd.puts "  /usr/sbin/ip route add #{route[:route].to_s(with_bits: true)} via #{route[:gw]}"
      end
    when :linux
      if route[:route].to_s(with_bits: true) == '0.0.0.0/0'
        @fd.puts '# Default (Will already be defined on router.)'
        @fd.puts "# /sbin/route add default #{route[:gw]}"
      else
        @fd.puts "# #{comment}"
        @fd.puts "  /sbin/route add -net #{route[:route].to_string} netmask #{route[:route].mask_to_s} gw #{route[:gw]}"
      end
    when :bsd
      if route[:route].to_s(with_bits: true) == '0.0.0.0/0'
        @fd.puts '# Default'
        @fd.puts "  /sbin/route add default #{route[:gw]}"
      else
        @fd.puts "# #{comment}"
        @fd.puts "  /sbin/route add -net #{route[:route].to_string} -netmask #{route[:route].mask_to_s} #{route[:gw]}"
      end
    when :ubnt_conf
      if route[:network_name] == 'default'
        @fd.puts "route.1.comment=#{comment}"
        @fd.puts "route.1.gateway=#{route[:gw]}"
        @fd.puts 'route.1.ip=0.0.0.0'
        @fd.puts "route.1.netmask=#{route[:route].mask_to_s}"
        @fd.puts 'route.1.status=enabled'
      else
        @route_count = @route_count == 0 ? 2 : @route_count + 1
        @fd.puts "route.#{@route_count}.comment=#{comment}"
        @fd.puts "route.#{@route_count}.gateway=#{route[:gw]}"
        @fd.puts "route.#{@route_count}.ip=#{route[:route].to_string}"
        @fd.puts "route.#{@route_count}.netmask=#{route[:route].mask_to_s}"
        @fd.puts "route.#{@route_count}.status=enabled"
      end
    when :zebra
      if route[:route].to_s(with_bits: true) == '0.0.0.0/0'
        @fd.puts '! Default'
        @fd.puts "ip route 0.0.0.0/0 #{route[:gw]}"
      else
        @fd.puts "! #{comment}"
        @fd.puts "ip route #{route[:route].to_s(with_bits: true)} #{route[:gw]}"
      end
    when :json
      if @route_count == 0
        @route_count += 1
      else
        @fd.puts ','
      end
      @fd.puts "// #{comment}"
      @fd.print "  { \"route\": \"#{route[:route].to_string}\", \"netmask\": \"#{route[:route].mask_to_s}\", \"gw\": \"#{route[:gw]}\"}"
    else # don't have a format for this, so make something up
      if route[:route].to_s(with_bits: true) == '0.0.0.0/0'
        @fd.puts '# Default'
        @fd.puts "  #{route[:gw]}"
      else
        @fd.puts "# #{comment}"
        @fd.puts "  #{route[:route].to_string} #{route[:route].mask_to_s} #{route[:gw]}"
      end
    end
  end

  def save_routes(routes:)
    return if routes.nil?

    res = routes.sort_by { |v| v[:route].to_i }
    res.each do |route|
      next if route[:local] # Don't need to output local interface routes.

      create_route_command(route: route, comment: "Network #{route[:network_name]}  via #{route[:node_name]} <--------")
    end
  end
end
