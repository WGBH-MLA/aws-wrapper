require_relative 'base_wrapper'
require 'resolv'

module DnsWrapper
  include BaseWrapper
  
  private
  
  def dns_client
    @dns_client ||= Aws::Route53::Client.new(client_config)
  end
  
  def wait_until_updates_propagate(request_id)
    1.upto(WAIT_ATTEMPTS) do |try|
      break if dns_client.get_change({id: request_id}).change_info.status == 'INSYNC'
      fail('Giving up') if try >= WAIT_ATTEMPTS
      LOGGER.info("try #{try}: DNS update #{request_id} not yet propagated to all AWS NS")
      sleep(WAIT_INTERVAL)
    end
  end
  
  public
  
  def lookup_cname(zone_id, name)
    cname_from_dns = Resolv::DNS.new.getresource(name, Resolv::DNS::Resource::IN::CNAME).name.to_s
    cname_from_aws = lookup_dns_cname_record(zone_id, name)
    if cname_from_dns != cname_from_aws
      fail("CNAME from DNS (#{cname_from_dns}) != CNAME from AWS (#{cname_from_aws})")
    end
    cname_from_aws
  end
  
  def lookup_dns_cname_record(zone_id, domain_name)
    resource_records = lookup_dns_cname_record_set(zone_id, domain_name).resource_records
    fail("Expected 1 resource record, not #{resource_records.count}") unless resource_records.count == 1
    resource_records[0].value
  end
  
  def lookup_dns_cname_record_set(zone_id, domain_name)
    response = dns_client.list_resource_record_sets({
      hosted_zone_id: zone_id, # required
      start_record_name: domain_name, # NOT a filter: all are returned, unless max_items set.
      start_record_type: 'CNAME', # accepts SOA, A, TXT, NS, CNAME, MX, PTR, SRV, SPF, AAAA
      # start_record_identifier: "ResourceRecordSetIdentifier",
      max_items: 1,
    })
    record_sets = response.resource_record_sets
    fail("Expected 1 record set, not #{record_sets.count}") unless record_sets.count == 1
    record_sets[0]
  end
  
# TODO: Delete all the code below when we're confident it's not needed.  
  
#  def lookup_dns(zone_id, domain_name)
#    aws_ip = lookup_dns_a_record(zone_id, domain_name)
#    dns_ip = Resolv.getaddress(domain_name)
#    fail("Discrepancy for #{domain_name}: AWS=#{aws_ip} but DNS=#{dns_ip}") unless dns_ip == aws_ip
#    dns_ip
#  end
  
#  def update_dns_a_record(zone_id, domain_name, new_ip)
#    update_response = request_update_dns_a_record(zone_id, domain_name, new_ip)
#    
#    1.upto(WAIT_ATTEMPTS) do |try|
#      break if update_insync?(update_response)
#      fail('Giving up') if try >= WAIT_ATTEMPTS
#      LOGGER.info("try #{try}: DNS update not yet propagated to AWS nameservers...")
#      sleep(WAIT_INTERVAL)
#    end
#    
#    1.upto(WAIT_ATTEMPTS) do |try|
#      break if Resolv.getaddress(domain_name) == new_ip
#      fail('Giving up') if try >= WAIT_ATTEMPTS
#      LOGGER.info("try #{try}: DNS update not yet propagated to local nameserver...")
#      sleep(WAIT_INTERVAL)
#    end
#  end
  
#  def update_insync?(update_request_response)
#    response = dns_client.get_change({
#      id: update_request_response.change_info.id
#    })
#    response.change_info.status == 'INSYNC'
#    # This means all the AWS NSs are up-to-date: 
#    # It does not imply that DNS records have
#    # been refreshed in all local caches.
#  end
  
#  def lookup_dns_a_record(zone_id, domain_name)
#    response = dns_client.list_resource_record_sets({
#      hosted_zone_id: zone_id, # required
#      start_record_name: domain_name, # NOT a filter: all are returned, unless max_items set.
#      start_record_type: 'A', # accepts SOA, A, TXT, NS, CNAME, MX, PTR, SRV, SPF, AAAA
#      # start_record_identifier: "ResourceRecordSetIdentifier",
#      max_items: 1,
#    })
#    record_sets = response.resource_record_sets
#    fail("Expected 1 record set, not #{record_sets.count}") unless record_sets.count == 1
#    resource_records = record_sets[0].resource_records
#    fail("Expected 1 resource record, not #{resource_records.count}") unless resource_records.count == 1
#    resource_records[0].value
#  end

  def cname_pair(name)
    [name, "demo.#{name}"].map do |name|
      name.downcase # Otherwise there are discrepancies between DNS and the API.
    end
  end
  
  # Since it takes a while for the updates to propagate, it makes sense to make
  # both requests first, and then wait for them to complete.
  
  def delete_dns_cname_records(zone_id, domain_names)
    domain_names.map do |domain_name|
      request_delete_dns_cname_record(zone_id, domain_name)
    end.each do |request_id|
      wait_until_updates_propagate(request_id)
    end
  end
  
  def create_dns_cname_records(zone_id, domain_name_target_hash)
    domain_name_target_hash.map do |domain_name, target|
      request_create_dns_cname_record(zone_id, domain_name, target)
    end.each do |request_id|
      wait_until_updates_propagate(request_id)
    end
  end
  
  def request_delete_dns_cname_record(zone_id, domain_name)
    # Annoyingly, you need to specify the entire record in order to delete:
    # Just the name is not enough.
    record_set = lookup_dns_cname_record_set(zone_id, domain_name)
    
    dns_client.change_resource_record_sets({
      hosted_zone_id: zone_id, # required
      change_batch: { # required
        # comment: "ResourceDescription",
        changes: [ # required
          {
            action: "DELETE", # required, accepts CREATE, DELETE, UPSERT
            resource_record_set: { # required
              name: domain_name, # required
              type: "CNAME", # required, accepts SOA, A, TXT, NS, CNAME, MX, PTR, SRV, SPF, AAAA
#              set_identifier: "ResourceRecordSetIdentifier",
#              weight: 1,
#              region: "us-east-1", # accepts us-east-1, us-west-1, us-west-2, eu-west-1, eu-central-1, ap-southeast-1, ap-southeast-2, ap-northeast-1, sa-east-1, cn-north-1
#              geo_location: {
#                continent_code: "GeoLocationContinentCode",
#                country_code: "GeoLocationCountryCode",
#                subdivision_code: "GeoLocationSubdivisionCode",
#              },
#              failover: "PRIMARY", # accepts PRIMARY, SECONDARY
              ttl: record_set.ttl, # required (but not documented as such)
              resource_records: record_set.resource_records,
#              alias_target: {
#                hosted_zone_id: "ResourceId", # required
#                dns_name: "DNSName", # required
#                evaluate_target_health: true, # required
#              },
#              health_check_id: "HealthCheckId",
            },
          },
        ],
      },
    }).change_info.id
  end
  
  
  def request_create_dns_cname_record(zone_id, domain_name, target)
    dns_client.change_resource_record_sets({
      hosted_zone_id: zone_id, # required
      change_batch: { # required
        # comment: "ResourceDescription",
        changes: [ # required
          {
            action: "CREATE", # required, accepts CREATE, DELETE, UPSERT
            resource_record_set: { # required
              name: domain_name, # required
              type: "CNAME", # required, accepts SOA, A, TXT, NS, CNAME, MX, PTR, SRV, SPF, AAAA
#              set_identifier: "ResourceRecordSetIdentifier",
#              weight: 1,
#              region: "us-east-1", # accepts us-east-1, us-west-1, us-west-2, eu-west-1, eu-central-1, ap-southeast-1, ap-southeast-2, ap-northeast-1, sa-east-1, cn-north-1
#              geo_location: {
#                continent_code: "GeoLocationContinentCode",
#                country_code: "GeoLocationCountryCode",
#                subdivision_code: "GeoLocationSubdivisionCode",
#              },
#              failover: "PRIMARY", # accepts PRIMARY, SECONDARY
              ttl: 300, # required (but not documented as such)
              resource_records: [
                {
                  value: target, # required
                }
              ],
#              alias_target: {
#                hosted_zone_id: "ResourceId", # required
#                dns_name: "DNSName", # required
#                evaluate_target_health: true, # required
#              },
#              health_check_id: "HealthCheckId",
            },
          },
        ],
      },
    }).change_info.id
  end
  
end
