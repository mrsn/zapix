require_relative 'base'

class Usergroups < Base

  def create(options)
    client.usergroup_create(options) unless exists?(options)
  end

  def exists?(options)
    client.usergroup_exists(options)
  end

  def get_id(options)
    if(exists?(options))
      result = client.usergroup_get({
        'filter' => {'name' => options['name']}})
      result.first['usrgrpid']
    else
      raise NonExistingUsergroup, "Usergroup #{options['name']} does not exist !"
    end
  end

  def delete(*group_ids)
    client.usergroup_delete(group_ids)
  end

  class NonExistingUsergroup < StandardError; end

end
