require_relative 'base_wrapper'

module ElbWrapper
  include BaseWrapper
  
  private
  
  def elb_client
    @elb_client ||= Aws::ElasticLoadBalancing::Client.new(CLIENT_CONFIG)
  end
  
  public 
  
  def lookup_elb_by_cname(cname)
    matches = elb_client.describe_load_balancers().load_balancer_descriptions.select do |elb|
      elb.dns_name == cname
    end
    fail("Expected exactly one LB with CNAME #{cname}, not #{matches.count}") if matches.count != 1
    matches.first
  end
  
end
