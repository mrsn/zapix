require_relative 'basic'

class Users < Basic
  def create(options)
    @client.user_create(options) unless exists?(options)
  end

  def exists?(options)
    result = @client.user_get({'filter' => {'alias' => options['alias']}})
    if result.empty?
      false
    else
      true
    end
  end

  def get_id(options)
    if(exists?(options))
      @client.user_get({'filter' => {'alias' => options['alias']}}).first['userid']
    else
      raise NonExistingUser, "User #{options['alias']} does not exist !"
    end
  end

  def delete(usergroup_ids)
    @client.user_delete(usergroup_ids)
  end

  class NonExistingUser < StandardError; end
end


