require_relative 'aws_wrapper'

class EbsMounter < AwsWrapper
  def mount(ec2_id)
    volume_id = create_volume()
    attach_volume_to_instance(volume_id, ec2_id, '/dev/sdb') 
  end
end
