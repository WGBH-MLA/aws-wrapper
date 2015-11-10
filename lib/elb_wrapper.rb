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
  
  def register_instance_with_elb(instance_id, elb_name)
    elb_client.register_instances_with_load_balancer({
      load_balancer_name: elb_name, # required
      instances: [ # required
        {
          instance_id: instance_id,
        },
      ],
    })
    # TODO: Wait for completion.
  end
  
  def deregister_instance_from_elb(instance_id, elb_name)
    elb_client.deregister_instances_from_load_balancer({
      load_balancer_name: elb_name, # required
      instances: [ # required
        {
          instance_id: instance_id,
        },
      ],
    })
    # TODO: Wait for completion.
  end
  
end
