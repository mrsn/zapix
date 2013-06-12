class Hosts < Basic

  def get_id(name)
    if(exists?(name))
      @client.host_get({"filter" => {"host" => name}}).first["hostid"]
    else
      raise NonExistingHost, "Host #{name} does not exist !"
    end
  end

  def create(options={})
    @client.host_create(options) unless exists?(options["host"])
  end

  def create_or_update(options={})
    if exists?(options["host"])
      id = get_id(options["host"])
      options.merge!("hostid" => id)
      @client.host_update(options)
    else
      create(options)
    end
  end

  def exists?(name)
    @client.host_exists({"host" => name})
  end

  def get_all
    host_names_and_ids = @client.host_get({"output" => ["name"]})

    # the fucking api ALWAYS returns the ids and that's
    # why we need to extract the names separately

    extract_host_names(host_names_and_ids)
  end

  def delete(name)
    if exists?(name)
      @client.host_delete(["hostid" => get_id(name)])
    else
      raise NonExistingHost, "Host #{name} cannot be deleted because it does not exist !"
    end
  end

  private

  def extract_host_names(hosts)
    host_names = Array.new
    hosts.each do |current_host|
      host_names << current_host["name"]
    end
    host_names
  end

class NonExistingHost < StandardError; end

end
