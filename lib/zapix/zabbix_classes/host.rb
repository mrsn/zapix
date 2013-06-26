class Host

  attr_accessor :group_ids, :template_ids, :interfaces, :macros

  def initialize()
    @group_ids = Array.new
    @template_ids = Array.new
    @interfaces = Array.new
    @macros = Array.new
    @properties = Hash.new
  end

  def add_name(name)
    @properties.merge!('host' => name)
  end

  def add_group_ids(*ids)
    ids.each do |id|
      group_ids << {'groupid' => id}
    end
    @properties.merge!('groups' => group_ids)
  end

  def add_interfaces(*ifaces)
    interfaces.concat(ifaces)
    @properties.merge!('interfaces' => interfaces)
  end

  def add_template_ids(*ids)
    ids.each do |id|
      template_ids << {'templateid' => id}
    end
    @properties.merge!('templates' => template_ids)
  end

  def add_macros(*host_macros)
    macros.concat(host_macros)
    @properties.merge!('macros' => host_macros)
  end

  def to_hash
    @properties
  end

end


