require_relative 'base_wrapper'

module IamWrapper
  include BaseWrapper
  
  private
  
  def iam_client
    @iam_client ||= Aws::IAM::Client.new(client_config)
  end
  
  public
  
  def create_group(name)
    iam_client.create_group({
      # path: optional
      group_name: name
    }).group
  end
  
end