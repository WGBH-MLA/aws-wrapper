require_relative '../lib/core/elb_wrapper'

describe ElbWrapper do
  def expect_wrapper
    wrapper = Class.new do
      include ElbWrapper
    end.new
    allow(wrapper).to receive(:elb_client).and_return(
      instance_double(Aws::ElasticLoadBalancing::Client).tap do |client|
        yield client
      end
    )
    wrapper
  end

  def expect_client_to_describe_elb(client, lb_description)
    allow(client).to receive(:describe_load_balancers)
      .and_return(
        instance_double(Aws::ElasticLoadBalancing::Types::DescribeAccessPointsOutput).tap do |output|
          allow(output).to receive(:load_balancer_descriptions)
            .and_return(
              [lb_description]
            )
        end
      )
  end

  def elb_description(opts)
    instance_double(Aws::ElasticLoadBalancing::Types::LoadBalancerDescription).tap do |description|
      opts.each do |key, value|
        allow(description).to receive(key).and_return(value)
      end
    end
  end

  def instance(instance_id)
    OpenStruct.new(instance_id: instance_id)
#    instance_double(Aws::ElasticLoadBalancing::Types::Instance) do |instance|
#      expect(instance).to receive(:instance_id).and_return(instance_id)
#    end
  end

  describe '#lookup_elb_by_dns_name' do
    it 'makes expected SDK calls' do
      dns_name = 'elb.cname.example.org'
      elb_description = elb_description(dns_name: dns_name)
      wrapper = expect_wrapper do |client|
        expect_client_to_describe_elb(client, elb_description)
      end
      expect(wrapper.lookup_elb_by_dns_name(dns_name)).to eq elb_description
    end
  end

  describe '#register_instance_with_elb' do
    it 'makes expected SDK calls' do
      instance_id = 'instance-id'
      elb_name = 'elb-name'
      elb_description = elb_description(load_balancer_name: elb_name, instances: [instance(instance_id)])
      wrapper = expect_wrapper do |client|
        allow(client).to receive(:register_instances_with_load_balancer)
        expect_client_to_describe_elb(client, elb_description)
      end
      expect { wrapper.register_instance_with_elb(instance_id, elb_name) }.not_to raise_error
    end
  end

  describe '#deregister_instance_from_elb' do
    it 'makes expected SDK calls' do
      instance_id = 'instance-id'
      elb_name = 'elb-name'
      elb_description = elb_description(load_balancer_name: elb_name, instances: [])
      wrapper = expect_wrapper do |client|
        allow(client).to receive(:deregister_instances_from_load_balancer)
        expect_client_to_describe_elb(client, elb_description)
      end
      expect { wrapper.deregister_instance_from_elb(instance_id, elb_name) }.not_to raise_error
    end
  end
end
