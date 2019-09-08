require 'ipaddr'

#Additions to the standard IPAddr class.
#I needed to be able to access the mask,
#test if a network is a subnet of another network
#Do simple additions to generate new IP addresses. 
class IPAddr
  #Expose mask in x.x.x.x format
  def mask_to_s
    _to_string(@mask_addr)
  end
  
  #Expose mask as integer
  def mask_to_i
    @mask_addr
  end
  
  #get mask in /n format, as integer. 
  #Probably a better method, but this will do for now.
  def mask_bits
    mask_bits = 0
    shifted_mask = @mask_addr
    (1..32).each do |i|
      mask_bits += 1 if(shifted_mask&0x1) == 1
      shifted_mask = shifted_mask >> 1
    end
    return mask_bits
  end
  
  alias to_s_orig to_s
  
  def to_s(with_bits: false)
    with_bits ? "#{_to_string(@addr)}/#{mask_bits}" : to_s_orig
  end
  
  def net_include?(ipaddr)
    self.include?(ipaddr) && @mask_addr <= ipaddr.mask_to_i
  end
  
  def +(value)
    self.clone.set(@addr + value, @family)
  end
end
