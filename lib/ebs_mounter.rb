require_relative 'aws_wrapper'

class EbsMounter < AwsWrapper
  def mount(ec2_id)
    create_and_attach_volume(ec2_id, '/dev/sdb') 
  end
end
