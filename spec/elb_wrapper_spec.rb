require_relative '../lib/elb_wrapper'

describe ElbWrapper do
  
  class TestWrapper
    include ElbWrapper
  end
  
  def expect_client_to_describe_lb(client, lb_description)
    expect(client).to receive(:describe_load_balancers)
      .and_return(
        instance_double(Aws::ElasticLoadBalancing::Types::DescribeAccessPointsOutput).tap do |output|
          expect(output).to receive(:load_balancer_descriptions)
            .and_return(
              [lb_description] 
            )
        end
      )
  end
  
  def elb_description(opts)
    instance_double(Aws::ElasticLoadBalancing::Types::LoadBalancerDescription).tap do |description|
      opts.each do |key, value|
        expect(description).to receive(key).and_return(value)
      end
    end
  end
  
  def instance(instance_id)
    OpenStruct.new(instance_id: instance_id)
#    instance_double(Aws::ElasticLoadBalancing::Types::Instance) do |instance|
#      expect(instance).to receive(:instance_id).and_return(instance_id)
#    end
  end
  
  describe '#lookup_elb_by_cname' do
    it 'makes expected SDK calls' do
      wrapper = TestWrapper.new
      dns_name = 'elb.cname.example.org'
      elb_description = elb_description(dns_name: dns_name)
      
      expect(wrapper).to receive(:elb_client).and_return(
        instance_double(Aws::ElasticLoadBalancing::Client).tap do |client|
          expect_client_to_describe_lb(client, elb_description)
        end
      )

      expect(wrapper.lookup_elb_by_cname(dns_name)).to eq elb_description
    end
  end

  describe '#lookup_elb_by_name' do
    it 'makes expected SDK calls' do
      wrapper = TestWrapper.new
      load_balancer_name = 'test-load-balancer'
      elb_description = elb_description(load_balancer_name: load_balancer_name)
      
      expect(wrapper).to receive(:elb_client).and_return(
        instance_double(Aws::ElasticLoadBalancing::Client).tap do |client|
          expect_client_to_describe_lb(client, elb_description)
        end
      )

      expect(wrapper.lookup_elb_by_name(load_balancer_name)).to eq elb_description
    end
  end
  
  describe '#register_instance_with_elb' do
    it 'makes expected SDK calls' do
      wrapper = TestWrapper.new
      instance_id = 'instance-id'
      elb_name = 'elb-name'
      elb_description = elb_description(load_balancer_name: elb_name, instances: [instance(instance_id)])
      
      expect(wrapper).to receive(:elb_client).and_return(
        instance_double(Aws::ElasticLoadBalancing::Client).tap do |client|
          expect(client).to receive(:register_instances_with_load_balancer)
          expect_client_to_describe_lb(client, elb_description)
        end
      ).at_most(2).times
      
      expect{wrapper.register_instance_with_elb(instance_id, elb_name)}.not_to raise_error
    end
  end
  
  describe '#deregister_instance_from_elb' do
    it 'makes expected SDK calls' do
      wrapper = TestWrapper.new
      instance_id = 'instance-id'
      elb_name = 'elb-name'
      elb_description = elb_description(load_balancer_name: elb_name, instances: [])
      
      expect(wrapper).to receive(:elb_client).and_return(
        instance_double(Aws::ElasticLoadBalancing::Client).tap do |client|
          expect(client).to receive(:deregister_instances_from_load_balancer)
          expect_client_to_describe_lb(client, elb_description)
        end
      ).at_most(2).times
      
      expect{wrapper.deregister_instance_from_elb(instance_id, elb_name)}.not_to raise_error
    end
  end

end
