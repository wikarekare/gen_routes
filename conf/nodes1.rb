require 'ipaddr'

#Definitions for each router on the network.
#Also definitions of distribution networks (each tower's client site networks.)
#Will fetch all these from the DB, but for testing, will use these definitions.
class Nodes
  
  def load_node_defs
    test_set_of_node_defs
    #nodes_from_db
  end
  
  def nodes_from_db
  end
    
  #Manual node definitions
  def test_set_of_node_defs
    @nodes = {
      #Three Routes out, vdsl1, vdsl2, vdsl3             
     'vdsl1' => { :interfaces => [ { :network_name => 'external5-net', :ipv4 => '114.23.248.105',  :network => '114.23.248.105/32', :route_hint => [] }, 
                                   { :network_name => 'dsl1-net', :ipv4 => '192.168.249.25', :network => '192.168.249.0/24', :route_hint => [] },
                                   # Can't move this one, as it wont allow networks other than 192.168 10 or 172 !
                                   #{ :network_name => 'dsl2-net', :ipv4 => '100.64.0.33', :network => '100.64.0.32/27', :route_hint => [] },
                                ],
                  :node_type => :manual,
                  :routes => []    
                },

     'vdsl2' => { :interfaces => [{ :network_name => 'external6-net', :ipv4 => '114.23.248.159', :network => '114.23.248.159/32', :route_hint => [] }, 
                                  { :network_name => 'dsl2-net', :ipv4 => '100.64.0.34', :network => '100.64.0.32/27', :route_hint => [] },
                                 ],
                  :node_type => :manual,
                  :routes => []    
                },

     'vdsl3' => { :interfaces => [{ :network_name => 'external7-net', :ipv4 => '121.99.244.68', :network => '121.99.244.68/32', :route_hint => [] },
                                  { :network_name => 'dsl2-net', :ipv4 => '100.64.0.35', :network => '100.64.0.32/27', :route_hint => [] },
                                 ],  
                  :node_type => :manual,
                  :routes => []    
                },
                
    #Firewall / Gateway. We define the default route here, rather than the VDSL routers, as it produces a neater resulting route list.
    'gate' => { :interfaces => [ { :network_name => 'wikk003-net', :ipv4 => '10.2.2.222', :network => '10.2.2.192/27', :route_hint => []}, 
                                 { :network_name => 'admin1-net', :ipv4 => '10.0.1.103', :network => '10.0.1.103/32', :route_hint => [] }, 
                                 { :network_name => 'dsl1-net', :ipv4 => '192.168.249.103', :network => '192.168.249.0/24', :route_hint => [{:network => '0.0.0.0/0', :network_name => 'default'}] },
                                 { :network_name => 'gate-net', :ipv4 => '100.64.0.1', :network => '100.64.0.0/27', :route_hint => [{:network => '100.64.0.0/10', :network_name => 'wikk-nets'},{:network => '10.0.0.0/8', :network_name => 'site-nets'},{:network => '192.168.0.0/16', :network_name => 'distribution-nets'}]}, 
                                 { :network_name => 'dsl2-net', :ipv4 => '100.64.0.36', :network => '100.64.0.32/27', :route_hint => [] },
                               ],  
                  :node_type => :bsd,
                  :routes => []    
                },
              
    #internal distirbuiton routers to client sites      
    'lk1t' => { :interfaces => [ { :network_name => 'lk1t-dist-net', :ipv4 => '192.168.219.1',  :network => '192.168.219.0/24', :route_hint => [{:network => '10.19.0.0/16', :network_name => 'lk1t-sites'}] },
                                 { :network_name => 'gate-net', :ipv4 => '100.64.0.5', :network => '100.64.0.0/27', :route_hint => [] }, 
                               ],
                  :node_type => :json,
                  :routes => []    
                },
 
    'lk2' => { :interfaces => [{ :network_name => 'lk2-dist-net', :ipv4 => '192.168.206.1',  :network => '192.168.206.0/24', :route_hint => [{:network => '10.6.0.0/16', :network_name => 'lk2-sites'}] },
                              { :network_name => 'gate-net', :ipv4 => '100.64.0.6', :network => '100.64.0.0/27', :route_hint => [] }, 
                              ],
                   :node_type => :linux,
                  :routes => []    
                },

    'lk4' => { :interfaces => [{ :network_name => 'lk4-dist-net', :ipv4 => '192.168.208.1',  :network => '192.168.208.0/24', :route_hint => [{:network => '10.8.0.0/16', :network_name => 'lk4-sites'}] },
                              { :network_name => 'lk4-net', :ipv4 => '10.8.0.30', :network => '10.8.0.0/27', :route_hint => [] },
                             ],
                  :node_type => :linux,
                  :routes => []    
                },

    'lk5' => { :interfaces => [{ :network_name => 'lk5-dist-net', :ipv4 => '192.168.209.1',  :network => '192.168.209.0/24', :route_hint => [{:network => '10.9.0.0/16', :network_name => 'lk5-sites'}] },
                              { :network_name => 'lk5-net', :ipv4 => '10.9.0.30', :network => '10.9.0.0/27', :route_hint => [] },
                              ],
                  :node_type => :linux,
                  :routes => []    
                },

    'lk6' => { :interfaces => [{ :network_name => 'lk6-dist-net', :ipv4 => '192.168.213.1',  :network => '192.168.213.0/24', :route_hint => [{:network => '10.13.0.0/16', :network_name => 'lk6-sites'}] },
                              { :network_name => 'lk6-net', :ipv4 => '10.13.1.30', :network => '10.13.1.0/27', :route_hint => [] },
                              ],
                  :node_type => :linux,
                  :routes => []    
                },

    'beach' => { :interfaces => [{ :network_name => 'beach-dist-net', :ipv4 => '192.168.203.1',  :network => '192.168.203.0/24', :route_hint => [{:network => '10.3.0.0/16', :network_name => 'beach-sites'}] },
                                { :network_name => 'beach-net', :ipv4 => '10.3.0.30', :network => '10.3.0.0/27', :route_hint => [] },
                                { :network_name => 'wikk006-net', :ipv4 => '10.3.1.158',  :network => '10.3.1.128/27', :route_hint => [] }, 
                                { :network_name => 'wikk030-net', :ipv4 => '10.3.1.94',  :network => '10.3.1.64/27', :route_hint => [] }, 
                                ],
                   :node_type => :zebra,
                  :routes => []    
                },

    'beach2' => { :interfaces => [{ :network_name => 'beach2-dist-net', :ipv4 => '192.168.218.1',  :network => '192.168.218.0/24', :route_hint => [{:network => '10.18.0.0/16', :network_name => 'beach2-sites'}] },
                                  { :network_name => 'beach-net', :ipv4 => '10.3.0.28', :network => '10.3.0.0/27', :route_hint => [] },
                                ],
                  :node_type => :linux,
                  :routes => []    
                },
 
    'barn' => { :interfaces => [{ :network_name => 'barn-dist-net', :ipv4 => '192.168.204.1',  :network => '192.168.204.0/24', :route_hint => [{:network => '10.4.0.0/16', :network_name => 'barn-sites'}] },
                                { :network_name => 'barn-net', :ipv4 => '10.4.1.30', :network => '10.4.1.0/27', :route_hint => [] },
                                ],
                   :node_type => :linux,
                  :routes => []    
                },

    'oceanview2' => { :interfaces => [{ :network_name => 'oceanview2-dist-net', :ipv4 => '192.168.215.1',  :network => '192.168.215.0/24', :route_hint => [{:network => '10.15.0.0/16', :network_name => 'oceanview2-sites'}] },
                                      { :network_name => 'oceanview-net', :ipv4 => '10.5.1.26', :network => '10.5.1.0/27', :route_hint => [] },
                                    ],
                  :node_type => :linux,
                  :routes => []    
                },
     
    'oceanview4' => { :interfaces => [{ :network_name => 'oceanview4-dist-net', :ipv4 => '192.168.217.1',  :network => '192.168.217.0/24', :route_hint => [{:network => '10.17.0.0/16', :network_name => 'oceanview4-sites'}] },
                                      { :network_name => 'oceanview-net', :ipv4 => '10.5.1.24', :network => '10.5.1.0/27', :route_hint => [] },
                                      ],
                  :node_type => :linux,
                  :routes => []    
                },

     'relay069' => { :interfaces => [{ :network_name => 'relay069-net', :ipv4 => '10.16.0.30',  :network => '10.16.0.0/27', :route_hint => [{:network => '10.16.0.0/16', :network_name => 'relay069-sites'}] },
                                    { :network_name => 'lk6-dist-net', :ipv4 => '192.168.213.14', :network => '192.168.213.0/24', :route_hint => [] },
                                    ], 
                  :node_type => :linux,
                  :routes => []    
                },
                
    #Backbone routers, interconnecting distribution sites and the gateway           
    'wikkb16' => { :interfaces => [ { :network_name => 'b16-b17-net', :ipv4 => '192.168.200.33',  :network => '192.168.200.32/30', :route_hint => [] },
                                    { :network_name => 'gate-net', :ipv4 => '100.64.0.7', :network => '100.64.0.0/27', :route_hint => [] }, 
                                  ],
                  :node_type => :linux,
                  :routes => []    
                },
  
    'wikkb17' => { :interfaces => [ { :network_name => 'b16-b17-net', :ipv4 => '192.168.200.34',  :network => '192.168.200.32/30', :route_hint => [] },
                                    { :network_name => 'lk3-net', :ipv4 => '10.4.1.30', :network => '10.4.1.0/27', :route_hint => [{:network => '10.7.0.0/16', :network_name => 'lk3-sites'}] }, 
                                    { :network_name => 'wikk166-net', :ipv4 => '10.7.1.94',  :network => '10.7.1.64/27', :route_hint => [] }, 
                                  ],
                  :node_type => :linux,
                  :routes => []    
                },

    'wikkb18' => { :interfaces => [{ :network_name => 'b18-b19-net', :ipv4 => '192.168.200.37',  :network => '192.168.200.36/30', :route_hint => [] },
                                    { :network_name => 'lk3-net', :ipv4 => '10.4.1.29', :network => '10.4.1.0/27', :route_hint => [] },
                                    ],
                  :node_type => :linux,
                  :routes => []    
                },

    'wikkb19' => { :interfaces => [{ :network_name => 'b18-b19-net', :ipv4 => '192.168.200.38',  :network => '192.168.200.36/30', :route_hint => [] },
                                  { :network_name => 'barn-net', :ipv4 => '10.4.1.29', :network => '10.4.1.0/27', :route_hint => [] },
                                  ],
                  :node_type => :linux,
                  :routes => []    
                },

    'wikkb20' => { :interfaces => [{ :network_name => 'b20-b21-net', :ipv4 => '192.168.200.50',  :network => '192.168.200.48/30', :route_hint => [] },
                                  { :network_name => 'lk3-net', :ipv4 => '10.4.1.28', :network => '10.4.1.0/27', :route_hint => [] },
                                  ],
                  :node_type => :linux,
                  :routes => []    
                },

    'wikkb21' => { :interfaces => [{ :network_name => 'b20-b21-net', :ipv4 => '192.168.200.49',  :network => '192.168.200.48/30', :route_hint => [] },
                                    { :network_name => 'lk4-net', :ipv4 => '10.8.0.29', :network => '10.8.0.0/27', :route_hint => [] },
                                    ],
                  :node_type => :linux,
                  :routes => []    
                },

    'wikkb26' => { :interfaces => [{ :network_name => 'b26-b27-net', :ipv4 => '192.168.200.97',  :network => '192.168.200.96/30', :route_hint => [] },
                                  { :network_name => 'gate-net', :ipv4 => '100.64.0.8', :network => '100.64.0.0/27', :route_hint => [] }, 
                                  ],
                   :node_type => :linux,
                  :routes => []    
                },
 
    'wikkb27' => { :interfaces => [{ :network_name => 'b26-b27-net', :ipv4 => '192.168.200.98',  :network => '192.168.200.96/30', :route_hint => [] },
                                   { :network_name => 'oceanview-net', :ipv4 => '10.5.1.29', :network => '10.5.1.0/27', :route_hint => [{:network => '10.5.0.0/16', :network_name => 'oceanview-sites'}] }, 
                                   ],
                  :node_type => :linux,
                  :routes => []    
                },
  
    'wikkb30' => { :interfaces => [{ :network_name => 'b30-b31-net', :ipv4 => '192.168.200.101',  :network => '192.168.200.100/30', :route_hint => [] },
                                  { :network_name => 'gate-net', :ipv4 => '100.64.0.9', :network => '100.64.0.0/27', :route_hint => [] }, 
                                  ],
                  :node_type => :linux,
                  :routes => []    
                },

    'wikkb31' => { :interfaces => [{ :network_name => 'b30-b31-net', :ipv4 => '192.168.200.102',  :network => '192.168.200.100/30', :route_hint => [] },
                                  { :network_name => 'lk6-net', :ipv4 => '10.13.1.29', :network => '10.13.1.0/27', :route_hint => [] }, 
                                  ],
                  :node_type => :linux,
                  :routes => []    
                },

    'wikkb32' => { :interfaces => [{ :network_name => 'b32-b33-net', :ipv4 => '192.168.200.105',  :network => '192.168.200.104/30', :route_hint => [] },
                                  { :network_name => 'lk6-net', :ipv4 => '10.13.1.6', :network => '10.13.1.0/27', :route_hint => [] },
                                  ],
                  :node_type => :linux,
                  :routes => []    
                },

    'wikkb33' => { :interfaces => [{ :network_name => 'b32-b33-net', :ipv4 => '192.168.200.106',  :network => '192.168.200.104/30', :route_hint => [] },
                                  { :network_name => 'lk5-net', :ipv4 => '10.9.0.29',  :network => '10.9.0.0/27', :route_hint => [] },
                                  { :network_name => 'wikk171-net', :ipv4 => '10.9.2.158',  :network => '10.9.2.128/27', :route_hint => [] },
                                  ],
                  :node_type => :linux,
                  :routes => []    
                },

    'wikkb34' => { :interfaces => [{ :network_name => 'b34-b35-net', :ipv4 => '192.168.200.109',  :network => '192.168.200.108/30', :route_hint => [] },
                                  { :network_name => 'gate-net', :ipv4 => '100.64.0.10', :network => '100.64.0.0/27', :route_hint => [] }, 
                                  ],
                  :node_type => :linux,
                  :routes => []    
                },

    'wikkb35' => { :interfaces => [{ :network_name => 'b34-b35-net', :ipv4 => '192.168.200.110',  :network => '192.168.200.108/30', :route_hint => [] },
                                  { :network_name => 'beach-net', :ipv4 => '10.3.0.29', :network => '10.3.0.0/27', :route_hint => [] },
                                   ],
                   :node_type => :linux,
                  :routes => []    
                },
             
    #Link from gateway to DSL routers         
    'wikkb36' => { :interfaces => [{ :network_name => 'dsl2-net', :ipv4 => '100.64.0.39', :network => '100.64.0.32/27', :route_hint => [] }, 
                                  ],
                  :node_type => :linux,
                  :routes => []    
                },

    'wikkb37' => { :interfaces => [{ :network_name => 'dsl2-net', :ipv4 => '100.64.0.40', :network => '100.64.0.32/27', :route_hint => [] }, 
                                  ],
                  :node_type => :linux,
                  :routes => []    
                },
    #Individual hosts routers with more than one host site connected           
    'db' =>     { :interfaces => [{ :network_name => 'admin2-net', :ipv4 => '10.0.1.102', :network => '10.0.1.102/32', :route_hint => [] }, 
                                  { :network_name => 'gate-net', :ipv4 => '100.64.0.4', :network => '100.64.0.0/27', :route_hint => []}, 
                                ],  
                  :node_type => :bsd,
                  :routes => []    
                },

    'wikk125' => { :interfaces => [{ :network_name => 'lk6-dist-net', :ipv4 => '192.168.213.25',  :network => '192.168.213.0/24', :route_hint => [] },
                                  { :network_name => 'wikk125-net', :ipv4 => '10.13.2.126', :network => '10.13.2.96/27', :route_hint => [] },
                                  { :network_name => 'wikk160-net', :ipv4 => '10.13.3.30', :network => '10.13.3.0/27', :route_hint => [] }, ],
                  :node_type => :linux,
                  :routes => []    
                },
  
    'wikk124' => { :interfaces => [{ :network_name => 'oceanview-net', :ipv4 => '10.5.1.3', :network => '10.5.1.0/27', :route_hint => [] },
                                  { :network_name => 'wikk124-net', :ipv4 => '10.5.4.94', :network => '10.5.4.64/27', :route_hint => [] },
                                  #{ :network_name => 'dsl2-net', :ipv4 => '100.64.0.41', :network => '100.64.0.32/27', :route_hint => [] }, 
                                   ],
                  :node_type => :linux,
                  :routes => []    
                },
              
    'relay069a' => { :interfaces => [{ :network_name => 'relay069-net', :ipv4 => '10.16.0.28',  :network => '10.16.0.0/27', :route_hint => [] },
                                    { :network_name => 'wikk130', :ipv4 => '10.16.2.30',  :network => '10.16.2.0/27', :route_hint => [] },
                                    { :network_name => 'wikk137', :ipv4 => '10.16.1.222',  :network => '10.16.1.192/27', :route_hint => [] },
                                    { :network_name => 'wikk155', :ipv4 => '10.16.2.94',  :network => '10.16.2.64/27', :route_hint => [] }, 
                                    ],
                  :node_type => :zebra,
                  :routes => []    
                },
                
    'relay069b' => { :interfaces => [{ :network_name => 'relay069-net', :ipv4 => '10.16.0.29',  :network => '10.16.0.0/27', :route_hint => [] },
                                    { :network_name => 'wikk126', :ipv4 => '10.16.1.62',  :network => '10.16.1.32/27', :route_hint => [] }, 
                                    { :network_name => 'wikk127', :ipv4 => '10.16.1.94',  :network => '10.16.1.64/27', :route_hint => [] }, 
                                    ],
                  :node_type => :zebra,
                  :routes => []    
                }
    }
  end
  
  def distribution_defs
    @distribution = {
      'barn' => { :distribution => '192.168.204.0/24', :gw => '192.168.204.1', :sites => '10.4.0.0/16', :site_mask => 27, :site_size => 32, :count => 48},
      'beach' => { :distribution => '192.168.203.0/24', :gw => '192.168.203.1', :sites => '10.3.0.0/16', :site_mask => 27, :site_size => 32, :count => 48},
      'beach2' => { :distribution => '192.168.218.0/24', :gw => '192.168.218.1', :sites => '10.18.0.0/16', :site_mask => 27, :site_size => 32, :count => 48},
      #'lk1' => { :distribution => nil, :gw => nil, :sites => '10.2.0.0/16', :site_mask => 27, :site_size => 32, :count => 48}, #Direct connect to gate
      'lk1t' => { :distribution => '192.168.219.0/24', :gw => '192.168.219.1', :sites => '10.19.0.0/16', :site_mask => 27, :site_size => 32, :count => 48},
      'lk2' => { :distribution => '192.168.206.0/24', :gw => '192.168.206.1', :sites => '10.6.0.0/16', :site_mask => 27, :site_size => 32, :count => 48},
      'lk4' => { :distribution => '192.168.208.0/24', :gw => '192.168.208.1', :sites => '10.8.0.0/16', :site_mask => 27, :site_size => 32, :count => 48},
      'lk5' => { :distribution => '192.168.209.0/24', :gw => '192.168.204.1', :sites => '10.9.0.0/16', :site_mask => 27, :site_size => 32, :count => 48},
      'lk6' => { :distribution => '192.168.213.0/24', :gw => '192.168.213.1', :sites => '10.13.0.0/16', :site_mask => 27, :site_size => 32, :count => 48},
      #'oceanview' => { :distribution => '192.168.205.0/24', :gw => '192.168.205.1', :sites => '10.5.0.0/16', :site_mask => 27, :site_size => 32, :count => 48}, #direct connect to wikkb27
      'oceanview2' => { :distribution => '192.168.215.0/24', :gw => '192.168.215.1', :sites => '10.15.0.0/16', :site_mask => 27, :site_size => 32, :count => 48},
      'oceanview4' => { :distribution => '192.168.217.0/24', :gw => '192.168.217.1', :sites => '10.17.0.0/16', :site_mask => 27, :site_size => 32, :count => 48},
      #'relay069' => { :distribution => nil, :gw => nil, :sites => '10.16.0.0/16', :site_mask => 27, :site_size => 32, :count => 48}, #Are direct connects, so are defined in @nodes
    }
  end
  
end