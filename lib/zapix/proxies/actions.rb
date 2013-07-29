require_relative 'basic'

class Actions < Basic
  def exists?(options)
    @client.action_exists(options)
  end
end
