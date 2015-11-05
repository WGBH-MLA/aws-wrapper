require_relative '../lib/ec2_wrapper'

describe Ec2Wrapper do
  
  class TestWrapper
    include Ec2Wrapper
  end
  
  describe '#lookup_eip' do
    it 'makes expected calls to AWS' do
      wrapper = TestWrapper.new
      expect(wrapper).to receive(:ec2_client).and_return(
        instance_double(Aws::EC2::Client).tap do |client|
          expect(client).to receive(:describe_addresses)
            .with(dry_run: false, public_ips: ["fake-eip-id"])
            .and_return(
              instance_double(Aws::EC2::Types::DescribeAddressesResult).tap do |result|
                expect(result).to receive(:addresses)
                  .and_return(['fake.eip.ip.address'])
                  .exactly(2).times # for logging and for real
              end
            )
        end
      )
      expect(wrapper.lookup_eip('fake-eip-id')).to eq 'fake.eip.ip.address'
    end
  end
  
  describe '#assign_eip' do
    it 'makes expected calls to AWS' do
      wrapper = TestWrapper.new
      expect(wrapper).to receive(:ec2_client).and_return(
        instance_double(Aws::EC2::Client).tap do |client|
          expect(client).to receive(:associate_address)
            .with(dry_run: false, instance_id: 'instance-id', public_ip: 'public.ip.address')
        end
      )
      instance = instance_double(Aws::EC2::Instance).tap do |instance|
        expect(instance).to receive(:instance_id).and_return('instance-id')
      end
      expect(wrapper.assign_eip('public.ip.address', instance)).to eq true
    end
  end
  
  describe '#lookup_instance' do
    it 'makes expected calls to AWS' do
      # TODO
    end
  end
  
end