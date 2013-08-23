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
templates_hostgroup = 'Templates'
application = 'web scenarios'
host = 'hostname'
scenario = 'scenario'
trigger_description = 'Webpage failed on {HOST.NAME}'
trigger_expression = "{#{host}:web.test.fail[#{scenario}].max(#3)}#0"
non_existing_trigger_expression = '{vfs.file.cksum[/etc/passwd].diff(0)}>0'
existing_action_name = 'Report problems to Zabbix administrators'
non_existing_action_name = 'No action defined'
test_usergroup = 'Operation managers test'
existing_usergroup = 'Zabbix administrators'
non_existing_usergroup = 'Smurfs'
existing_user = 'Admin'
non_existing_user = 'Tweegle'
test_user = 'Jim'
test_action = 'Test Action'

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
existing_action_name
  context 'complex hostgroup consisting hosts' do
    before(:each) do
      zrc.hostgroups.create(hostgroup_with_hosts)
      hostgroup_id = zrc.hostgroups.get_id(hostgroup_with_hosts)
      example_host = Host.new
      example_host.add_name(host)
      example_host.add_interfaces(create_interface.to_hash)
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
      example_host.add_interfaces(create_interface.to_hash)
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
      options['priority'] = 2 # 2 means Warning
      zrc.triggers.create(options)
      
    end

    after(:each) do
      zrc.hostgroups.delete(hostgroup_with_hosts)
    end

    describe 'hosts' do

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
        example_host.add_interfaces(create_interface.to_hash)
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
        # now it should be safe to update the interface of the host
        example_host = Host.new
        example_host.add_interfaces(create_interface.to_hash)
        example_host.add_name(host)
        zrc.hosts.create_or_update(example_host.to_hash)
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

      it 'creates a template' do
        template_name = 'Template Tomcat'
        options = {'host' => template_name}
        options['groups'] = zrc.hostgroups.get_id(templates_hostgroup)
        zrc.templates.create(options)
        zrc.templates.exists?(template_name).should be_true
      end
    end

    describe 'applications' do
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
    end

    describe 'web scenarios' do
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
        pending 'Not implemended'
        options = {}
        options['name'] = scenario
        options['hostid'] = zrc.hosts.get_id(host)
        zrc.scenarios.delete(options)
        zrc.scenarios.exists?(options).should be_false
      end
    end

    describe 'triggers' do
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
        (zrc.triggers.get_id(options)).to_i.should >= 0
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

    describe 'hostinterfaces' do
      it 'creates jmx interface for host' do
        jmx_iface = create_jmx_interface
        jmx_iface_hash = jmx_iface.to_hash
        jmx_iface_hash['hostid'] = zrc.hosts.get_id(host)
        zrc.hostinterfaces.create(jmx_iface_hash)
        zrc.hostinterfaces.exists?(jmx_iface_hash).should be_true
      end

      it 'check if interface exists for host' do
        options = {}
        options['hostid'] = zrc.hosts.get_id(host)
        options['port'] = 10050
        options['type'] = 1
        zrc.hostinterfaces.exists?(options).should be_true

        options['port'] = 9003
        options['type'] = 4
        zrc.hostinterfaces.exists?(options).should be_false
      end

      it 'gets interface id' do
        pending 'Not implemented'
      end

      it 'deletes an interface' do
        pending 'Not implemented'
      end
    end

    describe 'actions' do
      before(:each) do
        options = {}
        usergroup_options = {}
        usergroup_options['name'] = existing_usergroup
        options['name'] = test_action
        options['eventsource'] = 0
        options['evaltype'] = 1 # AND
        options['status'] = 1 # Disabled
        options['esc_period'] = 3600
        options['def_shortdata'] = '{TRIGGER.NAME}: {TRIGGER.STATUS}'
        options['def_longdata'] = "{TRIGGER.NAME}: {TRIGGER.STATUS}\r\nLast value: {ITEM.LASTVALUE}\r\n\r\n{TRIGGER.URL}"
        options['conditions'] = [{
          'conditiontype' => 0, # Hostgroup
          'operator'      => 0, # =
          'value' => zrc.hostgroups.get_id('Templates')
        },
        # not in maintenance
        {
          'conditiontype' => 16, # Maintenance
          'operator'      => 7,  # not in
          'value'         => 'maintenance'
        }]
        options['operations'] = [{
          'operationtype' => 0,
          'esc_period'     => 0,
          'esc_step_from'  => 1,
          'esc_step_to'    => 1,
          'evaltype'       => 0,
          'opmessage_grp'  => [{
            'usrgrpid' => zrc.usergroups.get_id(usergroup_options)
          }],
          'opmessage' => {
            'default_msg' => 1,
            'mediatypeid' => 1
          }
        }]
        zrc.actions.create(options)
      end

      after(:each) do
        options = {}
        options['name'] = test_action
        action_id = zrc.actions.get_id(options)
        zrc.actions.delete(action_id)
      end

      it 'checks if an action exists' do
        options = {}
        options['name'] = existing_action_name
        zrc.actions.exists?(options).should be_true
        options['name'] = non_existing_action_name
        zrc.actions.exists?(options).should be_false
      end

      it 'gets an id of an action' do
        options = {}
        options['name'] = test_action
        result = zrc.actions.get_id(options)
        (result.to_i).should >= 0
      end
    end

    describe 'usergroups' do
      before(:each) do
        options = {}
        options['name'] = test_usergroup
        options['rights'] = {
          'permission' => 3,
          'id' => zrc.hostgroups.get_id(hostgroup_with_hosts)
        }
        zrc.usergroups.create(options)
      end

      after(:each) do
        options = {}
        options['name'] = test_usergroup
        usergroup_id = zrc.usergroups.get_id(options)
        zrc.usergroups.delete(usergroup_id)
      end

      it 'checks if a usergroup exists' do
        options = {}
        options['name'] = existing_usergroup
        zrc.usergroups.exists?(options).should be_true
        options['name'] = non_existing_usergroup
        zrc.usergroups.exists?(options).should be_false
      end

      it 'gets the id of a usergroup by name' do
        options = {}
        options['name'] = test_usergroup
        result = zrc.usergroups.get_id(options)
        (result.to_i).should >= 0
        options['name'] = non_existing_usergroup
        expect { zrc.usergroups.get_id(options) }.to raise_error(Usergroups::NonExistingUsergroup)
      end
    end

    describe 'user' do
      before(:each) do
        user_options = {}
        group_options = {}
        group_options['name'] = existing_usergroup
        group_id = zrc.usergroups.get_id(group_options)
        user_options['alias'] = test_user
        user_options['passwd'] = random_string
        user_options['usrgrps'] = [{
          'usrgrpid' => group_id
        }]

        user_options['user_medias'] = [{
          'mediatypeid' => 1,
          'sendto' => 'support@company.com',
          'active' => 0,
          'severity' => 63,
          'period' => '1-7,00:00-24:00'
        }]
        zrc.users.create(user_options)
      end

      after(:each) do
        user_options = {}
        user_options['alias'] = test_user
        user_options['userid'] = zrc.users.get_id(user_options)
        zrc.users.delete(user_options)
      end

      it 'checks if a user exists' do
        options = {}
        options['alias'] = test_user
        zrc.users.exists?(options).should be_true
        options['alias'] = non_existing_user
        zrc.users.exists?(options).should be_false
      end

      it 'gets the id of a user' do
        options = {}
        options['alias'] = test_user
        result = zrc.users.get_id(options)
        (result.to_i).should >= 0
        options['alias'] = non_existing_user
        expect { zrc.users.get_id(options) }.to raise_error(Users::NonExistingUser)
      end
    end
  end

  def create_interface
    Interface.new(
      'ip'  => random_local_ip,
      'dns' => random_domain)
  end

  def create_jmx_interface
    Interface.new(
      'ip'  => random_local_ip,
      'dns' => random_domain,
      'type' => 4, # JMX
      'main' => 1, # default jmx interface
      'port' => 9003)
  end

  def random_string
    rand(36**7...36**8).to_s(36)
  end

  def random_int
    rand(64)
  end

  def random_local_ip
    "127.0.0.#{random_int}"
  end

  def random_domain
    "#{random_string}.our-cloud.de"
  end

end
