require_relative 'spec_helper'

@api_url = "http://cloud9.dyndns-server.com/zabbix/api_jsonrpc.php"
@api_login = "techuser"
@api_password = "kamelia"

zrc = ZabbixAPI.connect(
  :service_url => @api_url,
  :username => @api_login,
  :password => @api_password,
  :debug => true
  )

hostgroup = "hostgroup"
another_hostgroup = "anotherhostgroup"
hostgroup_with_hosts = "withhosts"
template_1 = "Template OS Linux"
template_2 = "Template App MySQL"
application = "application"
item = "item"
host = "hostname"
screen_name = "screen_name"
trigger = "trigger"
user = "user"
user2 = "user2"
usergroup = "SomeUserGroup"
graph = "graph"
mediatype = "somemediatype"

describe ZabbixAPI do

  context "hostgroup" do
    before(:all) do
      zrc.hostgroups.create(hostgroup)
      zrc.hostgroups.create(another_hostgroup)
    end

    after(:all) do
      zrc.hostgroups.delete(hostgroup)
      zrc.hostgroups.delete(another_hostgroup)
    end

    it "creates or updates a hostgroup" do
      zrc.hostgroups.create_or_update(hostgroup)
      result = zrc.hostgroups.create_or_update(hostgroup)
      result.should include("groupids")
    end

    it "returns false if hostgroup does not exist" do
      result = zrc.hostgroups.exists?("nonexisting")
      result.should be_false
    end

    it "succeeds if a hostgroup exist" do
      result = zrc.hostgroups.exists?(hostgroup)
      result.should be_true
    end

    it "returns hostgroup id" do
      result = zrc.hostgroups.get_id(hostgroup)
      (result.to_i).should >= 0
    end

    it "throws exception if hostgroup id does not exist" do
      expect { zrc.hostgroups.get_id("nonexisting") }.to raise_error(HostGroups::NonExistingHostgroup)
    end

    it "throws exception if someone checks for attached hosts of nonexisting group" do
     expect { zrc.hostgroups.any_hosts?("nonexisting") }.to raise_error(HostGroups::NonExistingHostgroup)
    end

    it "returns false if a hostgroup has no attached hosts" do
      zrc.hostgroups.any_hosts?(hostgroup).should be_false
    end

    it "returns all hostgroups" do
      (zrc.hostgroups.get_all).should include(hostgroup, another_hostgroup)
    end
  end

  context "complex hostgroup consisting hosts" do
    before(:each) do
      zrc.hostgroups.create(hostgroup_with_hosts)
      hostgroup_id = zrc.hostgroups.get_id(hostgroup_with_hosts)
      example_host = Host.new
      example_host.add_name(host)
      example_host.add_interfaces(create_interface)
      example_host.add_group_ids(hostgroup_id)
      example_host.add_template_ids(zrc.templates.get_id(template_1), zrc.templates.get_id(template_2))
      zrc.hosts.create_or_update(example_host.to_hash)
    end

     it "deletes a hostgroup with attached hosts" do
      zrc.hosts.exists?(host).should be_true
      zrc.hosts.get_all
      zrc.hosts.delete("hostname")
      zrc.hostgroups.delete(hostgroup_with_hosts)
    end
   
  end

  context "complex hostgroup should be easy to delete" do
    before(:each) do
      zrc.hostgroups.create(hostgroup_with_hosts)
      hostgroup_id = zrc.hostgroups.get_id(hostgroup_with_hosts)
      example_host = Host.new
      example_host.add_name(host)
      example_host.add_interfaces(create_interface)
      example_host.add_group_ids(hostgroup_id)
      example_host.add_template_ids(zrc.templates.get_id(template_1), zrc.templates.get_id(template_2))
      zrc.hosts.create_or_update(example_host.to_hash)
    end

    after(:each) do
      zrc.hosts.delete(host)
      zrc.hostgroups.delete(hostgroup_with_hosts)
    end

    it "returns true if a hostgroup has attached hosts" do
      zrc.hostgroups.any_hosts?(hostgroup_with_hosts).should be_true
    end

    it "returns all the host ids of a hosts belonging to a hostgroup" do
      host_id = zrc.hosts.get_id(host)
      zrc.hostgroups.get_host_ids_of(hostgroup_with_hosts).should include(host_id)
    end

    it "gets the right template id for host" do
      result = zrc.templates.get_templates_for_host(zrc.hosts.get_id(host))
      result.should include(zrc.templates.get_id(template_1))
      result.should include(zrc.templates.get_id(template_2))
    end

    it "unlinks all templates for host" do
      host_id = zrc.hosts.get_id(host)
      options = {}
      options["template_ids"] = zrc.templates.get_templates_for_host(host_id)
      options["host_id"] = host_id
      result = zrc.hosts.unlink_templates(options)
      result.should_not include(zrc.templates.get_id(template_1))
      result.should_not include(zrc.templates.get_id(template_2))
    end

    it "throws an exception if updating a host without specifying the hostname" do
      example_host = Host.new
      example_host.add_interfaces(create_interface)
      expect { zrc.hosts.create_or_update(example_host.to_hash) }.to raise_error(Hosts::EmptyHostname)
    end

    it "updates host after unlinking all belonging templates" do
      # unlinking all items
      host_id = zrc.hosts.get_id(host)
      options = {}
      zrc.templates.get_templates_for_host(host_id)
      options["template_ids"] = zrc.templates.get_templates_for_host(host_id)
      options["host_id"] = host_id
      result = zrc.hosts.unlink_templates(options)
      # now it should be safe to update the interface of the host
      example_host = Host.new
      example_host.add_interfaces(create_interface)
      example_host.add_name(host)
      zrc.hosts.create_or_update(example_host.to_hash)
    end

  end

  def create_interface
    Interface.new(
      "ip" => "127.0.0.#{random_int}",
      "dns" => "#{random_string}.our-cloud.de").to_hash
  end

  def random_string
    rand(36**7...36**8).to_s(36)
  end

  def random_int
    rand(64)
  end

end
