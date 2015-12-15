require_relative 'aws_wrapper'

class Lister < AwsWrapper
  def list(zone_id, name)
    {
      name: name,
      cnames: cname_info(zone_id, name)
    }
  end
  
  def cname_info(zone_id, name)
    cname_pair(name).map do |cname|
      elb_dns = lookup_cname(zone_id, cname)
      elb = lookup_elb_by_dns_name(elb_dns)
      elb_name = elb.load_balancer_name
      {
        cname: cname,
        elb_name: elb_name,
        groups: lookup_groups_by_resource('loadbalancer/'+elb_name),
        instances: elb.instances.map do |instance|
          #instance_info()
        end
      }
      
#      groups = lookup_groups_by_resource('loadbalancer/'+elb.load_balancer_name)
#      # A group could also be related to other resources: it is a many-to-many relationship
#      puts "Groups: #{groups}"
#      
#      elb.instances.each do |elb_instance|
#        instance = lookup_instance(elb_instance.instance_id)
#        puts 'Instance ID: '+instance.instance_id
#        puts 'Key name: '+instance.key_name
#        lookup_volume_ids(instance.instance_id).each do |volume_id|
#          puts 'Volume ID: '+volume_id
#          list_snapshots(volume_id).each do |snapshot|
#            puts 'Snapshot ID: '+snapshot.snapshot_id
#          end
#        end
#      end
    end
  end
end
