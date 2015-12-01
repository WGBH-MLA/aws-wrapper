require_relative 'aws_wrapper'

class GroupAdder < AwsWrapper
  # In this case the low-level method does exactly what we want,
  # but still making this class for the sake of consistency.
  #   add_user_to_group(user_name, group_name)
end
