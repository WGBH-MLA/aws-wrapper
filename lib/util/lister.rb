require_relative 'aws_wrapper'

class Lister < AwsWrapper
  def list(zone_id, name, is_flat=true)
    list = {
      name: name,
      cnames: cname_pair(name).map do |cname|
        cname_info(zone_id, cname)
      end
    }
    if is_flat
      cnames = list[:cnames]
      instances = cnames.map { |c| c[:instances] }.flatten
      volumes = instances.map { |i| i[:volumes] }.flatten
      # Only groups and key_name will be repeated in tree: only they need uniq.
      {
        cnames: cnames.map { |c| c[:cname] },
        elb_names: cnames.map { |c| c[:elb_name] },
        groups: cnames.map { |c| c[:groups] }.flatten.uniq,
        instance_ids: instances.map { |i| i[:instance_id] },
        key_names: instances.map { |i| i[:key_name] }.uniq,
        volume_ids: volumes.map { |v| v[:volume_id] },
        snapshot_ids: volumes.map { |v| v[:snapshot_ids] }.flatten
      }
    else
      list
    end
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
