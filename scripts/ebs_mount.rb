require_relative '../lib/ebs_mounter'

if ARGV.count != 1
  puts <<EOF
USAGE: #{File.basename(__FILE__)} ID

When run a new EBS is mounted on EC2 instance ID.
EOF
  exit 1
end

ec2_id = ARGV.shift

EbsMounter.new.mount(ec2_id)