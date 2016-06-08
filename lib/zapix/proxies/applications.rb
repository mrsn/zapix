require_relative 'base'

class Applications < Base

  def create(options)
    client.application_create(options) unless exists?(options)
  end

  def exists?(options)
    result = client.application_get({'filter' => {'name' => options['name']}})
    if (result == nil || result.empty?)
      false
    else
      true
    end
  end

  def get_id(options)
    if exists?(options)
      client.application_get({
        'filter' => {'name' => options['name'],
        'hostid' => options['hostid']}}).first['applicationids']
    else
      raise NonExistingApplication, "Application #{options['name']} does not exist !"
    end
  end

  class NonExistingApplication < StandardError; end

end
