require_relative "basic"

class HostGroups < Basic

def mass_create(*names)
  names.each do |group_name|
    create(group_name)
  end
end

def create(name)
  @client.hostgroup_create({"name" => name}) unless exists?(name)
end

def exists?(name)
  @client.hostgroup_exists({"name" => name})
end

def get_id(name)
  if(exists?(name))
    result = @client.hostgroup_get({"filter" => {"name" => [name]}})
    result[0]["groupid"]
  else
    raise NonExistingHostgroup, "Hostgroup #{name} does not exist !"
  end
end

def mass_delete(*names)
  names.each do |group_name|
    delete(group_name)
  end
end

def delete(name)
  if(exists?(name))
    group_id = get_id(name)
    @client.hostgroup_delete([group_id])
  else
    raise NonExistingHostgroup, "Hostgroup #{name} does not exist !"
  end
end

def get_all
  # the fucking API also returns the ids and that's
  # why we need to extract the names
  host_groups_with_ids = @client.hostgroup_get({"output" => ["name"]})
  extract_host_groups(host_groups_with_ids)
end

def extract_host_groups(group_names_and_ids)
  group_names_and_ids.map do |hostgroup|
    hostgroup["name"]
  end
end

class NonExistingHostgroup < StandardError; end

end
