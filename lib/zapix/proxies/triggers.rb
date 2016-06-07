require_relative 'base'
class Triggers < Base

=begin
  def exists?(options)
    #client.trigger_exists(options)
    result = client.template_get({'filter' => {'name' => name}})
    if result.empty?
      false
    else
      true
    end
  end
=end

  def create(options)
    #client.trigger_create(options) unless exists?(options)
    client.trigger_create(options)
  end

  def delete(*trigger_ids)
    client.trigger_delete(trigger_ids)
  end

  def get_id(options)
    result = client.trigger_get({'output' => 'extend',
      'expandExpression' => true})
    id = extract_id(result, options['expression'])
    unless id.nil?
      id
    else
      raise NonExistingTrigger, "Trigger with expression #{options['expression']} not found."
    end
  end

  class NonExistingTrigger < StandardError; end

  private

  def extract_id(triggers, expression)
    result = nil
    triggers.each do |trigger|
      if trigger['expression'] == expression
        result = trigger['triggerid']
        break
      end
    end
    result
  end

end


