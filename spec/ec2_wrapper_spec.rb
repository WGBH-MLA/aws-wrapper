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

  describe '#create_and_attach_volume' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:create_volume)
        .and_return(
          instance_double(Aws::EC2::Types::Volume).tap do |volume|
            expect(volume).to receive(:volume_id).and_return('volume-id')
          end
        )
        expect(client).to receive(:describe_volumes)
        .and_return(
          instance_double(Aws::EC2::Types::DescribeVolumesResult).tap do |result|
            expect(result).to receive(:volumes)
            .and_return(
              [
                instance_double(Aws::EC2::Types::Volume).tap do |volume|
                  expect(volume).to receive(:volume_id).and_return('volume-id')
                  expect(volume).to receive(:state).and_return('available')
                end
              ]
            )
          end
        )
        expect(client).to receive(:create_tags)
        expect(client).to receive(:attach_volume)
        expect(client).to receive(:modify_instance_attribute)
      end
      expect { wrapper.create_and_attach_volume('name', 'instance_id', 'device', 'size_in_gb', 'optional_snapshot_id') }.not_to raise_error
    end
  end

  describe '#create_snapshot' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:create_snapshot)
        .and_return(
          instance_double(Aws::EC2::Types::Snapshot).tap do |snapshot|
            expect(snapshot).to receive(:snapshot_id).and_return('snapshot-id')
          end
        )
        expect(client).to receive(:create_tags)
      end
      expect { wrapper.create_snapshot('name', 'volume_id', 'description') }.not_to raise_error
    end
  end

  describe '#delete_snapshot' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:delete_snapshot)
      end
      expect { wrapper.delete_snapshot('snapshot_id') }.not_to raise_error
    end
  end

  describe '#list_snapshots' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:describe_snapshots)
        .and_return(
          instance_double(Aws::EC2::Types::DescribeSnapshotsResult).tap do |result|
            expect(result).to receive(:snapshots).and_return([])
          end
        )
      end
      expect { wrapper.list_snapshots('volume-id') }.not_to raise_error
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

  # Plain '#lookup_volume_id' is a thin wrapper around this.
  describe '#lookup_volume_ids' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:describe_instances)
        .and_return(
          instance_double(Aws::EC2::Types::DescribeInstancesResult).tap do |result|
            expect(result).to receive(:reservations).and_return([
              instance_double(Aws::EC2::Types::Reservation).tap do |reservation|
                expect(reservation).to receive(:instances).and_return([
                  instance_double(Aws::EC2::Types::Instance).tap do |instance|
                    expect(instance).to receive(:block_device_mappings).and_return(
                      # These could be doubles too.
                      [OpenStruct.new(device_name: '/dev/your-name-here',
                                      ebs: OpenStruct.new(volume_id: 'volume-id'))]
                    )
                  end
                ])
              end
            ])
          end
        )
      end
      expect(wrapper.lookup_volume_ids('instance-id', '/dev/your-name-here')).to eq(['volume-id'])
    end
  end
end
