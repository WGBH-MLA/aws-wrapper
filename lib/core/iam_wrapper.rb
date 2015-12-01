require_relative 'base_wrapper'

module IamWrapper
  include BaseWrapper
  
  private
  
  def iam_client
    @iam_client ||= Aws::IAM::Client.new(client_config)
  end
  
  def current_user_name
    @current_user_name ||= Aws::IAM::CurrentUser.new.user_name
  end
  
  public
  
  def create_group(name)
    iam_client.create_group({
      # path: optional
      group_name: name
    }).group
  end
  
  def add_user_to_group(user_name, group_name)
    iam_client.add_user_to_group({
      group_name: group_name, # required
      user_name: user_name, # required
    })
  end
  
  def add_current_user_to_group(group_name)
    add_user_to_group(current_user_name, group_name)
  end
  
end