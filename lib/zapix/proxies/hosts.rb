require_relative 'base'
class Hosts < Base

  def get_id(name)
    if(exists?(name))
      client.host_get({'filter' => {'host' => name}}).first['hostid']
    else
      raise NonExistingHost, "Host #{name} does not exist !"
    end
  end

  def create(options={})
    client.host_create(options) unless exists?(options["host"])
  end

  def create_or_update(options={})
    raise EmptyHostname, 'Host name cannot be empty !' if options['host'].nil?
    if exists?(options['host'])
      id = get_id(options['host'])
      options.merge!('hostid' => id)
      client.host_update(options)
    else
      create(options)
    end
  end

  def unlink_and_clear_templates(options={})
    template_ids = options['template_ids'].map { |id| {'templateid' => id}}
    client.host_update({'hostid' => options['host_id'], 'templates_clear' => template_ids})
  end

  def update_templates(options={})
    template_ids = options['template_ids'].map { |id| {'templateid' => id}}
    client.host_update({'hostid' => options['host_id'], 'templates' => template_ids})
  end

  def update_macros(options={})
    client.host_update('hostid' => options['host_id'], 'macros' => options['macros'])
  end

  def exists?(name)
    #client.host_exists({'host' => name})
    result = client.host_get({'filter' => {'host' => name}})
    if result.empty? || result == nil
      false
    else
      true
    end
  end

  def get_all
    host_names_and_ids = client.host_get({'output' => ['name']})

    # the fucking api ALWAYS returns the ids and that's
    # why we need to extract the names separately

    extract_host_names(host_names_and_ids)
  end

  def delete(name)
    if exists?(name)
      client.host_delete([get_id(name)])
    else
      raise NonExistingHost, "Host #{name} cannot be deleted because it does not exist !"
    end
  end

  class NonExistingHost < StandardError; end
  class EmptyHostname < StandardError; end

  private

  def extract_host_names(hosts_and_ids)
    hosts_and_ids.map do |current_host|
      current_host['name']
    end
  end
end
