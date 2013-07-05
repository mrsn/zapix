require_relative 'spec_helper'

zrc = ZabbixAPI.connect(
  :service_url => ENV['ZABBIX_API_URL'],
  :username => ENV['ZABBIX_API_LOGIN'],
  :password => ENV['ZABBIX_API_PASSWORD'],
  :debug => true
  )

hostgroup = 'hostgroup'
another_hostgroup = 'anotherhostgroup'
hostgroup_with_hosts = 'withhosts'
template_1 = 'Template OS Linux'
template_2 = 'Template App MySQL'
application = 'web scenarios'
host = 'hostname'
scenario = 'scenario'
trigger_description = 'Webpage failed on {HOST.NAME}'
trigger_expression = "{#{host}:web.test.fail[#{scenario}].max(#3)}#0"
non_existing_trigger_expression = '{vfs.file.cksum[/etc/passwd].diff(0)}>0'

describe ZabbixAPI do

  context 'hostgroup' do
    before(:all) do
      zrc.hostgroups.create(hostgroup)
      zrc.hostgroups.create(another_hostgroup)
    end

    after(:all) do
      zrc.hostgroups.delete(hostgroup)
      zrc.hostgroups.delete(another_hostgroup)
    end

    it 'creates or updates a hostgroup' do
      zrc.hostgroups.create_or_update(hostgroup)
      result = zrc.hostgroups.create_or_update(hostgroup)
      result.should include('groupids')
    end

    it 'returns false if hostgroup does not exist' do
      result = zrc.hostgroups.exists?('nonexisting')
      result.should be_false
    end

    it 'succeeds if a hostgroup exist' do
      result = zrc.hostgroups.exists?(hostgroup)
      result.should be_true
    end

    it 'returns hostgroup id' do
      result = zrc.hostgroups.get_id(hostgroup)
      (result.to_i).should >= 0
    end

    it 'throws exception if hostgroup id does not exist' do
      expect { zrc.hostgroups.get_id('nonexisting') }.to raise_error(HostGroups::NonExistingHostgroup)
    end

    it 'throws exception if someone checks for attached hosts of nonexisting group' do
     expect { zrc.hostgroups.any_hosts?('nonexisting') }.to raise_error(HostGroups::NonExistingHostgroup)
    end

    it 'returns false if a hostgroup has no attached hosts' do
      zrc.hostgroups.any_hosts?(hostgroup).should be_false
    end

    it 'returns all hostgroups' do
      (zrc.hostgroups.get_all).should include(hostgroup, another_hostgroup)
    end
  end

  context 'complex hostgroup consisting hosts' do
    before(:each) do
      zrc.hostgroups.create(hostgroup_with_hosts)
      hostgroup_id = zrc.hostgroups.get_id(hostgroup_with_hosts)
      example_host = Host.new
      example_host.add_name(host)
      example_host.add_interfaces(create_interface)
      example_host.add_group_ids(hostgroup_id)
      example_host.add_template_ids(zrc.templates.get_id(template_1), zrc.templates.get_id(template_2))
      example_host.add_macros({'macro' => '{$TESTMACRO}', 'value' => 'test123'})
      zrc.hosts.create_or_update(example_host.to_hash)
    end

     it 'deletes a hostgroup with attached hosts' do
      zrc.hosts.exists?(host).should be_true
      zrc.hostgroups.delete(hostgroup_with_hosts)
      zrc.hostgroups.exists?(hostgroup_with_hosts).should be_false
    end
   
  end

  context 'complex hostgroup' do
    before(:each) do
      zrc.hostgroups.create(hostgroup_with_hosts)
      hostgroup_id = zrc.hostgroups.get_id(hostgroup_with_hosts)
      example_host = Host.new
      example_host.add_name(host)
      example_host.add_interfaces(create_interface)
      example_host.add_macros({'macro' => '{$TESTMACRO}', 'value' => 'test123'})
      example_host.add_group_ids(hostgroup_id)
      example_host.add_template_ids(zrc.templates.get_id(template_1), zrc.templates.get_id(template_2))
      zrc.hosts.create_or_update(example_host.to_hash)

      # create application for the host
      application_options = {}
      application_options['name'] = application
      application_options['hostid'] = zrc.hosts.get_id(host)
      zrc.applications.create(application_options)

      # creates web scenarios for host
      webcheck_options = {}
      webcheck_options['hostid'] = zrc.hosts.get_id(host)
      webcheck_options['name'] = scenario
      webcheck_options['applicationid'] = zrc.applications.get_id(application_options)
      webcheck_options['steps'] = [{'name' => 'Homepage', 'url' => 'm.test.de', 'status_codes' => 200, 'no' => 1}]
      zrc.scenarios.create(webcheck_options)

      # creates a trigger
      options = {}
      options['description'] = trigger_description
      options['expression'] = trigger_expression
      options['priority'] = '2' # 2 means Warning
      zrc.triggers.create(options)
      
    end

    after(:each) do
      zrc.hostgroups.delete(hostgroup_with_hosts)
    end

    it 'returns true if a hostgroup has attached hosts' do
      zrc.hostgroups.any_hosts?(hostgroup_with_hosts).should be_true
    end

    it 'returns all the host ids of a hosts belonging to a hostgroup' do
      host_id = zrc.hosts.get_id(host)
      zrc.hostgroups.get_host_ids_of(hostgroup_with_hosts).should include(host_id)
    end

    it 'gets the right template id for host' do
      result = zrc.templates.get_templates_for_host(zrc.hosts.get_id(host))
      result.should include(zrc.templates.get_id(template_1))
      result.should include(zrc.templates.get_id(template_2))
    end

    it 'unlinks all templates for host' do
      host_id = zrc.hosts.get_id(host)
      options = {}
      options['template_ids'] = zrc.templates.get_templates_for_host(host_id)
      options['host_id'] = host_id
      result = zrc.hosts.unlink_and_clear_templates(options)
      result.should_not include(zrc.templates.get_id(template_1))
      result.should_not include(zrc.templates.get_id(template_2))
    end

    it 'throws an exception if updating a host without specifying the hostname' do
      example_host = Host.new
      example_host.add_interfaces(create_interface)
      expect { zrc.hosts.create_or_update(example_host.to_hash) }.to raise_error(Hosts::EmptyHostname)
    end

    it "updates host's interface after unlinking all belonging templates" do
      # unlinking all items
      host_id = zrc.hosts.get_id(host)
      options = {}
      zrc.templates.get_templates_for_host(host_id)
      options['template_ids'] = zrc.templates.get_templates_for_host(host_id)
      options['host_id'] = host_id
      result = zrc.hosts.unlink_and_clear_templates(options)
      #result = zrc.hosts.update_templates(options)
      # now it should be safe to update the interface of the host
      example_host = Host.new
      example_host.add_interfaces(create_interface)
      example_host.add_name(host)
      zrc.hosts.create_or_update(example_host.to_hash)
      # check
    end

    it "updates host's templates" do
      host_id = zrc.hosts.get_id(host)
      options = {}
      options['host_id'] = host_id
      template_id = zrc.templates.get_id('Template App Agentless')
      options['template_ids'] = [template_id]
      zrc.hosts.update_templates(options)
      zrc.templates.get_templates_for_host(host_id).should include(template_id)
    end

    it "updates host's macro" do
      host_id = zrc.hosts.get_id(host)
      options = {}
      options['host_id'] = host_id
      options['macros'] = [{'macro' => '{$TESTMACRO}', 'value' => 'this is only a test macro'}]
      zrc.hosts.update_macros(options)
    end

    it 'returns false if an application does not exist' do
      options = {}
      options['name'] = 'nonexisting'
      options['hostid'] = zrc.hosts.get_id(host)
      zrc.applications.exists?(options).should be_false
    end

    it 'returns true if an application exists' do
      options = {}
      options['name'] = application
      options['hostid'] = zrc.hosts.get_id(host)
      zrc.applications.exists?(options).should be_true
    end

    it 'get an application id by application name and host' do
      options = {}
      options['name'] = application
      options['hostid'] = zrc.hosts.get_id(host)
      result = zrc.applications.get_id(options)
      (result.to_i).should >= 0
    end

    it 'throws exception on non existing application' do
      options = {}
      options['name'] = "nonexisting"
      options['hostid'] = zrc.hosts.get_id(host)
      expect { zrc.applications.get_id(options) }.to raise_error(Applications::NonExistingApplication)
    end

    it 'returns true if web scenarios exists' do
      options = {}
      options['name'] = scenario
      options['hostid'] = zrc.hosts.get_id(host)
      zrc.scenarios.exists?(options).should be_true
    end

    it 'gets the id of a web scenario' do
      options = {}
      options['name'] = scenario
      options['hostid'] = zrc.hosts.get_id(host)
      zrc.scenarios.exists?(options).should be_true
      zrc.scenarios.get_id(options)
    end

    it 'returns false if a web scenario does not exist' do
      options = {}
      options['name'] = "nonexisting"
      options['hostid'] = zrc.hosts.get_id(host)
      zrc.scenarios.exists?(options).should be_false
    end

    it 'deletes a web scenario' do
      pending 'Not ready'
      options = {}
      options['name'] = scenario
      options['hostid'] = zrc.hosts.get_id(host)
      zrc.scenarios.delete(options)
      zrc.scenarios.exists?(options).should be_false
    end

    it 'deletes a trigger' do
      options = {}
      options['expression'] = trigger_expression
      zrc.triggers.exists?(options).should be_true
      id = zrc.triggers.get_id(options)
      zrc.triggers.delete(id)
      zrc.triggers.exists?(options).should be_false
    end

    it 'gets an id of a trigger' do
      options = {}
      options['expression'] = trigger_expression
      zrc.triggers.get_id(options).should >= 0
    end

    it 'throws exception if trying to get id of a non-existing trigger' do
      options = {}
      options['expression'] = non_existing_trigger_expression
      expect { zrc.triggers.get_id(options) }.to raise_error(Triggers::NonExistingTrigger)
    end

    it 'returns true if a trigger exists' do
      options = {}
      options['expression'] = trigger_expression
      zrc.triggers.exists?(options).should be_true
    end

    it 'returns false if a trigger does not exist' do
      options = {}
      options['expression'] = non_existing_trigger_expression
      zrc.triggers.exists?(options).should be_false
    end
  end

  def create_interface
    Interface.new(
      'ip' => "127.0.0.#{random_int}",
      'dns' => "#{random_string}.our-cloud.de").to_hash
  end

  def random_string
    rand(36**7...36**8).to_s(36)
  end

  def random_int
    rand(64)
  end

end
