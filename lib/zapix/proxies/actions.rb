require_relative 'base'

class Actions < Base
  def exists?(options)
    result = client.action_get({'filter' => {'name' => options['name']}})
    if (result == nil || result.empty?)
      return false
    else
      return true
    end
  end

  def create(options)
    client.action_create(options) unless exists?(options)
  end

  def get_id(options)
    result = client.action_get({
      'filter' => {'name' => options['name']}})
      result.first['actionid']
  end

  def delete(*action_ids)
    client.action_delete(action_ids)
  end
end
