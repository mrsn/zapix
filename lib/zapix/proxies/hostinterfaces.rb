require_relative 'basic'

class Hostinterfaces < Basic

  def create(options)
    @client.hostinterface_create(options) unless exists?(options)
  end

  def exists?(options)
    if get(options).empty?
      false
    else
      true
    end
  end

  def get(options)
    @client.hostinterface_get(
      {'filter' => {'hostid' => options['hostid'],
      'port' => options['port'],
      'type' => options['type']},
      'output' => 'extend'})
  end

end
