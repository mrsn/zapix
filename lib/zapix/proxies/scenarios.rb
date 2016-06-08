require_relative 'base'

class Scenarios < Base
  def create(options)
    client.httptest_create(options) unless exists?(options)
  end

  def get_id(options)
    client.httptest_get({
      'filter' => {'name' => options['name'],
      'hostid' => options['hostid']}})
  end

  def delete(options)
    client.httptest_delete(options)
  end

  def exists?(options)
    result = client.httptest_get({
      'countOutput' => true,
      'filter' => {'name' => options['name'],
      'hostid' => options['hostid']}})

    result.to_i >= 1 ? true : false
  end

  def get_all
    scenarios = client.httptest_get({'output' => 'extend'})
    names = extract_names(scenarios)
  end

  def extract_names(scenarios)
    scenarios.map {|scenario| scenario['name']} 
  end
end
