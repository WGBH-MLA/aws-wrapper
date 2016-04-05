require_relative 'base_wrapper'
require 'resolv'

module DnsWrapper
  include BaseWrapper

  def cname_pair(name)
    [name, "demo.#{name}"].map(&:downcase)
  end

  def lookup_cname(zone_name, name)
    cname_from_dns = Resolv::DNS.new.getresource(name, Resolv::DNS::Resource::IN::CNAME).name.to_s
    cname_from_aws = lookup_dns_cname_record(zone_name, name)
    if cname_from_dns != cname_from_aws
      fail("CNAME from DNS (#{cname_from_dns}) != CNAME from AWS (#{cname_from_aws})")
    end
    cname_from_aws
  end

  # Since it takes a while for the updates to propagate, it makes sense to make
  # both requests first, and then wait for them to complete.

  def delete_dns_cname_records(zone_name, domain_names)
    domain_names.map do |domain_name|
      request_delete_dns_cname_record(zone_name, domain_name)
    end.each do |request_id|
      wait_until_updates_propagate(request_id)
    end
  end

  def create_dns_cname_records(zone_name, domain_name_target_hash)
    domain_name_target_hash.map do |domain_name, target|
      request_create_dns_cname_record(zone_name, domain_name, target)
    end.each do |request_id|
      wait_until_updates_propagate(request_id)
    end
  end

  private

  def dns_client
    @dns_client ||= Aws::Route53::Client.new(client_config)
  end

  def wait_until_updates_propagate(request_id)
    1.step do |try|
      break if dns_client.get_change(id: request_id).change_info.status == 'INSYNC'
      fail('Giving up') if try >= WAIT_ATTEMPTS
      LOGGER.info("try #{try}: DNS update #{request_id} not yet propagated to all AWS NS")
      sleep(WAIT_INTERVAL)
    end
  end

  def lookup_zone(zone_name)
    # We assume that the zone list will be stable, because the creation
    # and deletion of zones is not something our wrapper worries about.
    unless @zones
      response = dns_client.list_hosted_zones(
        max_items: 100
      )
      @zones = Hash[response.hosted_zones.map { |zone| [zone.name, zone.id.sub(/.*\//, '')] }]
      # Zone IDs returned by AWS are of the form '/hostedzone/ABCD1234'
    end
    @zones[zone_name]
  end

  def lookup_dns_cname_record(zone_name, domain_name)
    resource_records = lookup_dns_cname_record_set(zone_name, domain_name).resource_records
    fail("Expected 1 resource record for '#{domain_name}' in '#{zone_name}', not #{resource_records.count}") unless resource_records.count == 1
    resource_records[0].value
  end

  def lookup_dns_cname_record_set(zone_name, domain_name)
    zone_id = lookup_zone(zone_name)
    response = dns_client.list_resource_record_sets(
      hosted_zone_id: zone_id, # required
      start_record_name: domain_name, # NOT a filter: all are returned, unless max_items set.
      start_record_type: 'CNAME', # accepts SOA, A, TXT, NS, CNAME, MX, PTR, SRV, SPF, AAAA
      # start_record_identifier: "ResourceRecordSetIdentifier",
      max_items: 1)
    record_sets = response.resource_record_sets
    fail("Expected 1 record set for '#{domain_name}' in '#{zone_name}', not #{record_sets.count}") unless record_sets.count == 1
    record_sets[0]
  end

  def request_delete_dns_cname_record(zone_name, domain_name)
    # Annoyingly, you need to specify the entire record in order to delete:
    # Just the name is not enough.
    record_set = lookup_dns_cname_record_set(zone_name, domain_name)
    zone_id = lookup_zone(zone_name)
    dns_client.change_resource_record_sets(
      hosted_zone_id: zone_id, # required
      change_batch: { # required
        # comment: "ResourceDescription",
        changes: [ # required
          {
            action: 'DELETE', # required, accepts CREATE, DELETE, UPSERT
            resource_record_set: { # required
              name: domain_name, # required
              type: 'CNAME', # required, accepts SOA, A, TXT, NS, CNAME, MX, PTR, SRV, SPF, AAAA
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
            }
          }
        ]
      }).change_info.id
  end

  def request_create_dns_cname_record(zone_name, domain_name, target)
    zone_id = lookup_zone(zone_name)
    dns_client.change_resource_record_sets(
      hosted_zone_id: zone_id, # required
      change_batch: { # required
      # comment: "ResourceDescription",
        changes: [ # required
          {
            action: 'CREATE', # required, accepts CREATE, DELETE, UPSERT
            resource_record_set: { # required
              name: domain_name, # required
              type: 'CNAME', # required, accepts SOA, A, TXT, NS, CNAME, MX, PTR, SRV, SPF, AAAA
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
            }
          }
        ]
      }).change_info.id
  end
end
