require_relative 'base_wrapper'

module ElbWrapper
  include BaseWrapper
  
  private
  
  def elb_client
    @elb_client ||= Aws::ElasticLoadBalancing::Client.new(client_config)
  end
  
  public
  
  def create_elb(name)
    elb_client.create_load_balancer({
      load_balancer_name: name, # required
      listeners: [ # required
        {
          protocol: 'HTTP', # required
          load_balancer_port: 80, # required
          instance_protocol: 'HTTP',
          instance_port: 80, # required
          # ssl_certificate_id: "SSLCertificateId",
        }
      ],
      # Either AvailabilityZones or SubnetIds must be specified
      availability_zones: [AVAILABILITY_ZONE],
#      subnets: ["SubnetId"],
#      security_groups: ["SecurityGroupId"],
#      scheme: "LoadBalancerScheme",
#      tags: [
#        {
#          key: "TagKey", # required
#          value: "TagValue",
#        },
#      ],
    }).dns_name
  end
  
  def lookup_elb_by_cname(cname)
    matches = elb_client.describe_load_balancers().load_balancer_descriptions.select do |elb|
      elb.dns_name == cname
    end
    fail("Expected exactly one LB with CNAME #{cname}, not #{matches.count}") if matches.count != 1
    matches.first
  end
  
  def lookup_elb_by_name(name)
    matches = elb_client.describe_load_balancers().load_balancer_descriptions.select do |elb|
      elb.load_balancer_name == name
    end
    fail("Expected exactly one LB with name #{name}, not #{matches.count}") if matches.count != 1
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
    1.upto(WAIT_ATTEMPTS) do |try|
      break if lookup_elb_by_name(elb_name).instances.map(&:instance_id).include?(instance_id)
      fail('Giving up') if try >= WAIT_ATTEMPTS
      LOGGER.info("try #{try}: Instance #{instance_id} not yet registered with ELB #{elb_name}")
      sleep(WAIT_INTERVAL)
    end
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
    1.upto(WAIT_ATTEMPTS) do |try|
      break unless lookup_elb_by_name(elb_name).instances.map(&:instance_id).include?(instance_id)
      fail('Giving up') if try >= WAIT_ATTEMPTS
      LOGGER.info("try #{try}: Instance #{instance_id} not yet de-registered from ELB #{elb_name}")
      sleep(WAIT_INTERVAL)
    end
  end
  
end
