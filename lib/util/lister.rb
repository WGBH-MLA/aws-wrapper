require_relative 'aws_wrapper'

class Lister < AwsWrapper
  def list(zone_id, name)
    {
      name: name,
      cnames: cname_pair(name).map do |cname|
        cname_info(zone_id, cname)
      end
    }
  end

  private

  def cname_info(zone_id, cname)
    elb_dns = lookup_cname(zone_id, cname)
    elb = lookup_elb_by_dns_name(elb_dns)
    elb_name = elb.load_balancer_name
    {
      cname: cname,
      elb_name: elb_name,
      groups: lookup_groups_by_resource('loadbalancer/' + elb_name),
      instances: elb.instances.map do |elb_instance|
        instance_info(elb_instance)
      end
    }
  end

  def instance_info(elb_instance)
    instance_id = elb_instance.instance_id
    instance = lookup_instance(instance_id)
    {
      instance_id: instance_id,
      key_name: instance.key_name,
      volumes: lookup_volume_ids(instance_id).map do |volume_id|
        volume_info(volume_id)
      end
    }
  end

  def volume_info(volume_id)
    {
      volume_id: volume_id,
      snapshot_ids: list_snapshots(volume_id).map(&:snapshot_id)
    }
  end
end
