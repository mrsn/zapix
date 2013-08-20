require_relative 'base'

class HostGroups < Base

  def mass_create(*names)
    names.each do |group_name|
      create(group_name)
    end
  end

  def create(name)
    client.hostgroup_create({'name' => name}) unless exists?(name)
  end

  def create_or_update(name)
    if(exists?(name))
      id = get_id(name)
      client.hostgroup_update({'groupid' => id,'name' => name})
    else
      create(name)
    end
  end

  def exists?(name)
    client.hostgroup_exists({'name' => name})
  end

  def get_id(name)
    if(exists?(name))
      result = client.hostgroup_get({'filter' => {'name' => [name]}})
      result[0]['groupid']
    else
      raise NonExistingHostgroup, "Hostgroup #{name} does not exist !"
    end
  end

  def mass_delete(*names)
    names.each do |group_name|
      delete(group_name)
    end
  end

  def get_host_ids_of(hostgroup)
    result = client.hostgroup_get('filter' => {'name' => [hostgroup]}, 'selectHosts' => 'refer')
    extract_host_ids(result)
  end

  def any_hosts?(hostgroup)
    raise NonExistingHostgroup, "Hostgroup #{hostgroup} does not exist !" unless exists?(hostgroup)
    result = client.hostgroup_get('filter' => {'name' => [hostgroup]}, 'selectHosts' => 'count').first['hosts'].to_i
    result >= 1 ? true : false
  end

  def delete(name)
    if(exists?(name))
      # host cannot exist without a hostgroup, so we need to delete 
      # the attached hosts also
      if(any_hosts?(name))
        # delete all hosts attached to a hostgroup
        host_ids = get_host_ids_of(name)
        host_ids.each do |id|
          client.host_delete(['hostid' => id])
        end
        # now it is ok to delete the group
        client.hostgroup_delete([get_id(name)])
      else
        client.hostgroup_delete([get_id(name)])
      end
    else
      raise NonExistingHostgroup, "Hostgroup #{name} does not exist !"
    end
  end

  def get_all
    # the fucking API also returns the ids and that's
    # why we need to extract the names
    host_groups_with_ids = client.hostgroup_get({'output' => ['name']})
    extract_host_groups(host_groups_with_ids)
  end

  def extract_host_ids(query_result)
    query_result.first['hosts'].map { |host| host['hostid'] }
  end

  def extract_host_groups(group_names_and_ids)
    group_names_and_ids.map do |hostgroup|
      hostgroup['name']
    end
  end

  class NonExistingHostgroup < StandardError; end
end
