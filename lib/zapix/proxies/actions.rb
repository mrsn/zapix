require_relative 'basic'

class Actions < Basic
  def exists?(options)
    @client.action_exists(options)
  end

  def create(options)
    @client.action_create(options) unless exists?(options)
  end

  def get_id(options)
    result = @client.action_get({
      'filter' => {'name' => options['name']}})
      result.first['actionid']
  end

  def delete(*action_ids)
    @client.action_delete(action_ids)
  end
end
