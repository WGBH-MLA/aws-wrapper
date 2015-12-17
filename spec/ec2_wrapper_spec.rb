require_relative '../lib/core/ec2_wrapper'

describe Ec2Wrapper do
  def expect_wrapper
    wrapper = Class.new do
      include Ec2Wrapper
    end.new
    allow(wrapper).to receive(:ec2_client).and_return(
      instance_double(Aws::EC2::Client).tap do |client|
        yield client
      end
    )
    allow(wrapper).to receive(:availability_zone).and_return(
      'mock-availability-zone'
    )
    wrapper
  end

  describe '#create_key' do
    it 'makes expected SDK calls' do
      kp = instance_double(Aws::EC2::Types::KeyPair)
      wrapper = expect_wrapper do |client|
        allow(client).to receive(:create_key_pair).and_return(kp)
      end
      expect(wrapper.create_key('name', false)).to eq kp
    end
  end

  describe '#start_instances' do
    it 'makes expected SDK calls' do
      def instance(id)
        instance_double(Aws::EC2::Types::Instance).tap do |instance|
          allow(instance).to receive(:instance_id)
            .and_return(id).at_least(:once)
        end
      end

      instances = ['instance-1-id', 'instance-2-id'].map { |id| instance(id) }

      wrapper = expect_wrapper do |client|
        allow(client).to receive(:run_instances)
        .and_return(
          instance_double(Aws::EC2::Types::Reservation).tap do |reservation|
            allow(reservation).to receive(:instances)
              .and_return(instances)
          end
        )
        expect(client).to receive(:create_tags).exactly(2).times
        expect(client).to receive(:wait_until)
      end

      expect(wrapper.start_instances(2, 'testing', 'mock-instance-type', 'mock-image-id')).to eq instances
    end
  end
end
