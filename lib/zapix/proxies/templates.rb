class Templates < Basic

def exists?(name)
  @client.template_exists({"name" => name})
end

def create(name)
end

def delete(name)
end

def get_id(name)
  if(exists?(name))
    p @client.template_get({"filter" => {"name" => name}}).first["templateid"]
  else
    raise NonExistingTemplate, "Template #{name} does not exist !"
  end
end

class NonExistingTemplate < StandardError; end

end
