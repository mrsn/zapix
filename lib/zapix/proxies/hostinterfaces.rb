require_relative 'base'

class Hostinterfaces < Base

  def create(options)
    client.hostinterface_create(options) unless exists?(options)
  end

  def exists?(options)
    get(options).empty? ? false : true
  end

  def get(options)
    client.hostinterface_get(
      {'filter' => {'hostid' => options['hostid'],
      'port' => options['port'],
      'type' => options['type']},
      'output' => 'extend'})
  end

end
