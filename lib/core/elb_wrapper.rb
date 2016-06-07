require_relative 'base_wrapper'

module ElbWrapper
  include BaseWrapper

  def elb_arn(elb_name)
    account_id = Aws::IAM::CurrentUser.new.arn.match(/^arn:aws:iam::(\d+)/)[1]
    "arn:aws:elasticloadbalancing:#{availability_zone}:#{account_id}:loadbalancer/#{elb_name}"
  end

  def elb_names(name)
    %w(a b).map { |i| "#{name.gsub(/\W+/, '-')}-#{i}".downcase }
  end

  def create_elb(name)
    dns_name = elb_client.create_load_balancer(
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
      availability_zones: [availability_zone],
#      subnets: ["SubnetId"],
#      security_groups: ["SecurityGroupId"],
#      scheme: "LoadBalancerScheme",
#      tags: [
#        {
#          key: "TagKey", # required
#          value: "TagValue",
#        },
#      ],
    ).dns_name

    elb_client.configure_health_check(
      load_balancer_name: name, # required
      health_check: { # required
        target: 'HTTP:80/', # required, must contain ":"
        interval: 20, # required, >= 5
        timeout: 10, # required, >= 2, and < interval
        unhealthy_threshold: 10, # required, >= 2
        healthy_threshold: 2, # required, >= 2
      }
    )

    dns_name
  end

  def delete_elb(name)
    elb_client.delete_load_balancer(
      load_balancer_name: name, # required
    )
  end

  def lookup_elb_by_dns_name(cname)
    matches = elb_client.describe_load_balancers.load_balancer_descriptions.select do |elb|
      elb.dns_name == cname
    end
    fail("Expected exactly one LB with CNAME #{cname}, not #{matches.count}") if matches.count != 1
    matches.first
  end

  def register_instance_with_elb(instance_id, elb_name)
    elb_client.register_instances_with_load_balancer(load_balancer_name: elb_name, # required
                                                     instances: [ # required
                                                       {
                                                         instance_id: instance_id
                                                       }
                                                     ])
    wait_until do |try|
      LOGGER.info("try #{try}: Instance #{instance_id} not yet registered with ELB #{elb_name}")
      lookup_elb_by_name(elb_name).instances.map(&:instance_id).include?(instance_id)
    end
  end

  def deregister_instance_from_elb(instance_id, elb_name)
    elb_client.deregister_instances_from_load_balancer(load_balancer_name: elb_name, # required
                                                       instances: [ # required
                                                         {
                                                           instance_id: instance_id
                                                         }
                                                       ])
    wait_until do |try|
      LOGGER.info("try #{try}: Instance #{instance_id} not yet de-registered from ELB #{elb_name}")
      !lookup_elb_by_name(elb_name).instances.map(&:instance_id).include?(instance_id)
    end
  end

  private

  def elb_client
    @elb_client ||= Aws::ElasticLoadBalancing::Client.new(client_config)
  end

  def lookup_elb_by_name(name)
    matches = elb_client.describe_load_balancers.load_balancer_descriptions.select do |elb|
      elb.load_balancer_name == name
    end
    fail("Expected exactly one LB with name #{name}, not #{matches.count}") if matches.count != 1
    matches.first
  end
end
