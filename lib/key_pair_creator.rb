require_relative 'aws_wrapper'

class KeyPairCreator < AwsWrapper
  def create(name)
    create_key(name)
  end
end
