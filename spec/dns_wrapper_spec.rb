require_relative '../lib/core/dns_wrapper'

describe DnsWrapper do
  def mock_wrapper
    wrapper = Class.new do
      include DnsWrapper
    end.new
    allow(wrapper).to receive(:dns_client).and_return(
      instance_double(Aws::Route53::Client).tap do |client|
        yield client
      end
    )
    allow(wrapper).to receive(:availability_zone).and_return(
      'mock-availability-zone'
    )
    wrapper
  end

  describe '#cname_pair' do
    it 'has expected form' do
      expect(mock_wrapper {}.cname_pair('foo')).to eq(['foo', 'demo.foo'])
    end
  end

  describe '#lookup_cname' do
    xit 'makes expected SDK calls' do
      # TODO: Need to figure out how to mock Resolv::DNS.
    end
  end

  describe '#delete_dns_cname_records' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        allow(client).to receive(:list_resource_record_sets).and_return(
          instance_double(Aws::Route53::Types::ListResourceRecordSetsResponse).tap do |response|
            allow(response).to receive(:resource_record_sets).and_return(
              [OpenStruct.new]
            ).twice
          end
        ).twice
        allow(client).to receive(:change_resource_record_sets).and_return(
          OpenStruct.new(change_info: OpenStruct.new(id: 'id'))
        ).twice
        allow(client).to receive(:get_change).and_return(
          OpenStruct.new(change_info: OpenStruct.new(status: 'INSYNC'))
        ).twice
      end
      expect { wrapper.delete_dns_cname_records('zone-id', ['a.example.org', 'b.example.org']) }.not_to raise_error
    end
  end

  describe '#create_dns_cname_records' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        expect(client).to receive(:change_resource_record_sets).and_return(
          OpenStruct.new(change_info: OpenStruct.new(id: 'id'))
        )
        expect(client).to receive(:get_change).and_return(
          OpenStruct.new(change_info: OpenStruct.new(status: 'INSYNC'))
        )
      end
      expect { wrapper.create_dns_cname_records('zone-id', 'example.org' => 'target.example.org') }.not_to raise_error
    end
  end
end
