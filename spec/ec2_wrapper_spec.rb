require_relative '../lib/ec2_wrapper'

describe Ec2Wrapper do
  
  def expect_wrapper
    wrapper = Class.new do
      include Ec2Wrapper
    end.new
    expect(wrapper).to receive(:ec2_client).and_return(
      instance_double(Aws::EC2::Client).tap do |client|
        yield client
      end
    ).at_least(:once)
    wrapper
  end

  describe '#create_key' do
    it 'makes expected SDK calls' do
      kp = instance_double(Aws::EC2::Types::KeyPair)
      wrapper = expect_wrapper do |client|
        expect(client).to receive(:create_key_pair).and_return(kp)
      end
      expect(wrapper.create_key('name',false)).to eq kp
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
      
      instances = ['instance-1-id', 'instance-2-id'].map{ |id| instance(id) }
      
      wrapper = expect_wrapper do |client|
        expect(client).to receive(:run_instances)
          .and_return(
            instance_double(Aws::EC2::Types::Reservation).tap do |reservation|
              expect(reservation).to receive(:instances)
                .and_return(instances)
            end
          )
        expect(client).to receive(:wait_until)
      end
      
      expect(wrapper.start_instances(2, 'testing')).to eq instances
    end
  end


  
#  describe '#lookup_eip' do
#    it 'makes expected calls to AWS' do
#      wrapper = TestWrapper.new
#      expect(wrapper).to receive(:ec2_client).and_return(
#        instance_double(Aws::EC2::Client).tap do |client|
#          expect(client).to receive(:describe_addresses)
#            .with(dry_run: false, public_ips: ["eip-id"])
#            .and_return(
#              instance_double(Aws::EC2::Types::DescribeAddressesResult).tap do |result|
#                expect(result).to receive(:addresses)
#                  .and_return(['eip.ip.address'])
#                  .exactly(2).times # for logging and for real
#              end
#            )
#        end
#      )
#      
#      expect(wrapper.lookup_eip('eip-id')).to eq 'eip.ip.address'
#    end
#  end
#  
#  describe '#assign_eip' do
#    it 'makes expected calls to AWS' do
#      wrapper = TestWrapper.new
#      expect(wrapper).to receive(:ec2_client).and_return(
#        instance_double(Aws::EC2::Client).tap do |client|
#          expect(client).to receive(:associate_address)
#            .with(dry_run: false, instance_id: 'instance-id', public_ip: 'public.ip.address')
#        end
#      )
#      instance = instance_double(Aws::EC2::Instance).tap do |instance|
#        expect(instance).to receive(:instance_id).and_return('instance-id')
#      end
#      
#      expect(wrapper.assign_eip('public.ip.address', instance)).to eq true
#    end
#  end
#  
#  describe '#lookup_instance' do
#    it 'makes expected calls to AWS' do
#      wrapper = TestWrapper.new
#      expect(wrapper).to receive(:ec2_client).and_return(
#        instance_double(Aws::EC2::Client).tap do |client|
#          expect(client).to receive(:describe_instances)
#            .with(dry_run: false, instance_ids: ['instance-id'])
#            .and_return(
#              instance_double(Aws::EC2::Types::DescribeInstancesResult).tap do |result|
#                expect(result).to receive(:reservations)
#                  .and_return([
#                    instance_double(Aws::EC2::Types::Reservation).tap do |reservation|
#                      expect(reservation).to receive(:instances)
#                        .and_return([
#                          :instance
#                        ])
#                    end  
#                  ])
#              end
#            )
#        end
#      )
#      
#      expect(wrapper.lookup_instance('instance-id')).to eq :instance
#    end
#  end
  
end