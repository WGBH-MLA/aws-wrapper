require_relative 'base_wrapper'
require 'json'

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
  
  def delete_group(group_name)
    list_users_in_group(group_name).each do |user_name|
      iam_client.remove_user_from_group({
        group_name: group_name, # required
        user_name: user_name, # required
      })
    end
    iam_client.delete_group({
      # path: optional
      group_name: group_name
    })
  end
  
  def list_users_in_group(group_name)
    iam_client.get_group({
      group_name: group_name # required
      # marker: "markerType",
      # max_items: 1,
    }).users.map(&:user_name)
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
  
  def put_group_policy(group_name, statement)
    iam_client.put_group_policy({
      group_name: group_name, # required
      policy_name: group_name, # required
      policy_document: {
        'Version' => '2012-10-17',
        'Statement' => statement
      }.to_json, # required
    })
  end
  
  def delete_group_policy(group_name)
    iam_client.delete_group_policy({
      group_name: group_name, # required
      policy_name: group_name # required
    })
  end
  
end