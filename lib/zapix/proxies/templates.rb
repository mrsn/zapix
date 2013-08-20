require_relative 'base'
class Templates < Base

  def exists?(name)
    client.template_exists({'name' => name})
  end

  def get_id(name)
    if(exists?(name))
      client.template_get({'filter' => {'name' => name}}).first['templateid']
    else
      raise NonExistingTemplate, "Template #{name} does not exist !"
    end
  end

  def get_templates_for_host(id)
    client.template_get({'hostids' => [id]}).map { |result_set| result_set['templateid'] }
  end

  class NonExistingTemplate < StandardError; end
end
