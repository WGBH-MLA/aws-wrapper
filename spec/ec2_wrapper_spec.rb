require_relative '../lib/core/ec2_wrapper'

describe Ec2Wrapper do
  def mock_wrapper
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
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:create_key_pair).and_return(kp)
      end
      expect(wrapper.create_key('name', false)).to eq kp
    end
  end

  describe '#start_instances' do
    it 'makes expected SDK calls' do
      def instance(id)
        instance_double(Aws::EC2::Types::Instance).tap do |instance|
          expect(instance).to receive(:instance_id)
            .and_return(id).at_least(:once)
        end
      end

      instances = ['instance-1-id', 'instance-2-id'].map { |id| instance(id) }

      wrapper = mock_wrapper do |client|
        expect(client).to receive(:run_instances)
        .and_return(
          instance_double(Aws::EC2::Types::Reservation).tap do |reservation|
            expect(reservation).to receive(:instances)
            .and_return(instances)
          end
        )
        expect(client).to receive(:create_tags).exactly(2).times
        expect(client).to receive(:wait_until)
      end

      expect(wrapper.start_instances(2, 'testing', 'mock-instance-type', 'mock-image-id')).to eq instances
    end
  end

  describe '#create_tag' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:create_tags)
      end
      expect { wrapper.create_tag('id', 'key', 'value') }.not_to raise_error
    end
  end

  describe '#key_path' do
    it 'has expected form' do
      expect(mock_wrapper {}.key_path('name')).to match(/\/\.ssh\/name\.pem$/)
    end
  end

  describe '#delete_key' do
    # TODO: Does a File.delete, which could be risky.
  end

  describe '#terminate_instances_by_key' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:describe_instances)
        .and_return(
          instance_double(Aws::EC2::Types::DescribeInstancesResult).tap do |result|
            expect(result).to receive(:reservations).and_return([])
          end
        )
        expect(client).to receive(:terminate_instances)
      end
      expect { wrapper.terminate_instances_by_key('key') }.not_to raise_error
    end
  end

  describe '#terminate_instances_by_id' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:terminate_instances)
      end
      expect { wrapper.terminate_instances_by_id('id') }.not_to raise_error
    end
  end

  describe '#stop_instances_by_id' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:stop_instances)
      end
      expect { wrapper.stop_instances_by_id('id') }.not_to raise_error
    end
  end

  describe '#lookup_instance' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:describe_instances)
        .and_return(
          instance_double(Aws::EC2::Types::DescribeInstancesResult).tap do |result|
            expect(result).to receive(:reservations).and_return([
              instance_double(Aws::EC2::Types::Reservation).tap do |reservation|
                expect(reservation).to receive(:instances).and_return([
                  instance_double(Aws::EC2::Types::Instance)
                ])
              end
            ])
          end
        )
      end
      expect { wrapper.lookup_instance('id') }.not_to raise_error
    end
  end

  describe '#lookup_public_ips_by_name' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:describe_instances)
        .and_return(
          instance_double(Aws::EC2::Types::DescribeInstancesResult).tap do |result|
            expect(result).to receive(:reservations).and_return([
              instance_double(Aws::EC2::Types::Reservation).tap do |reservation|
                expect(reservation).to receive(:instances).and_return([
                  instance_double(Aws::EC2::Types::Instance).tap do |instance|
                    expect(instance).to receive(:public_ip_address).and_return('1.2.3.4')
                  end
                ])
              end
            ])
          end
        )
      end
      expect(wrapper.lookup_public_ips_by_name('foo')).to eq ['1.2.3.4']
      # expect { wrapper.lookup_public_ips_by_name('id') }.not_to raise_error
    end
  end
end
