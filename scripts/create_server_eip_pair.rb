require 'aws-sdk'

region = 'us-east-1'

ec2_client = Aws::EC2::Client.new(region: region)
resp = ec2_client.run_instances({
  dry_run: true,
  image_id: "ami-cf1066aa", # PV EBS-Backed 64-bit / US East
  min_count: 1, # required
  max_count: 1, # required
  key_name: "aapb", # TODO: Command-line parameter? Script to create in the first place?
  instance_type: "t1.micro",
  monitoring: {
    enabled: true, # required
  },
  disable_api_termination: false,
  instance_initiated_shutdown_behavior: "terminate", # accepts stop, terminate
})

puts resp
