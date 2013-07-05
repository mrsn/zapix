require_relative 'basic'

class Applications < Basic

  def create(options)
    @client.application_create(options) unless exists?(options)
  end

  def exists?(options)
    @client.application_exists(options)
  end

  def get_id(options)
    if exists?(options)
      @client.application_get({
        'filter' => {'name' => options['name'],
        'hostid' => options['hostid']}}).first['applicationid']
    else
      raise NonExistingApplication, "Application #{options['name']} does not exist !"
    end
  end

  class NonExistingApplication < StandardError; end

end
