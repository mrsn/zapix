require_relative 'basic'

class Scenarios < Basic
  def create(options)
    @client.webcheck_create(options) unless exists?(options)
  end

  def get_id(options)
    @client.webcheck_get({
      'filter' => {'name' => options['name'],
      'hostid' => options['hostid']}})
  end

  def delete(options)
    @client.webcheck_delete(options)
  end

  def exists?(options)
    result = @client.webcheck_get({
      'countOutput' => true,
      'filter' => {'name' => options['name'],
      'hostid' => options['hostid']}})
    if result.to_i >= 1
      true
    else
      false
    end
  end
end
