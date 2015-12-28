require_relative '../lib/core/iam_wrapper'

describe IamWrapper do
  def mock_wrapper
    wrapper = Class.new do
      include IamWrapper
    end.new
    allow(wrapper).to receive(:iam_client).and_return(
      instance_double(Aws::IAM::Client).tap do |client|
        yield client
      end
    )
    wrapper
  end
  
  describe '#create_group' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        allow(client).to receive(:create_group).and_return(
          OpenStruct.new(group: {})
        )
      end
      expect { wrapper.create_group('foo') }.not_to raise_error
    end
  end

  describe '#delete_group' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        allow(client).to receive(:get_group).and_return(
          OpenStruct.new(users: {})
        )
        allow(client).to receive(:delete_group)
      end
      expect { wrapper.delete_group('foo') }.not_to raise_error
    end
  end

  describe '#add_user_to_group' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        allow(client).to receive(:add_user_to_group)
      end
      expect { wrapper.add_user_to_group('user','group') }.not_to raise_error
    end
  end

  describe '#add_current_user_to_group' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        allow(client).to receive(:add_user_to_group)
      end
      expect { wrapper.add_current_user_to_group('foo') }.not_to raise_error
    end
  end

  describe '#lookup_groups_by_resource' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        allow(client).to receive(:list_groups).and_return(
          OpenStruct.new(groups: [])
        )
      end
      expect { wrapper.lookup_groups_by_resource('foo') }.not_to raise_error
    end
  end

  describe '#put_group_policy' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        allow(client).to receive(:put_group_policy)
      end
      expect { wrapper.put_group_policy('group','statement') }.not_to raise_error
    end
  end

  describe '#delete_group_policy' do
    it 'makes expected SDK calls' do
      wrapper = mock_wrapper do |client|
        allow(client).to receive(:delete_group_policy)
      end
      expect { wrapper.delete_group_policy('foo') }.not_to raise_error
    end
  end
end
