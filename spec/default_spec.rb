require 'chefspec'

%w{ debian rhel }.each do |platform_family|
  describe "The shorewall::default for #{platform_family}" do
    before (:all) {
      @chef_run = ChefSpec::ChefRunner.new
      @chef_run.node.automatic_attrs["platform_family"] = platform_family
      @chef_run.node.set["shorewall"] = {
        "zone_interfaces" => {"lan" => "eth0"}
      }
      @chef_run.converge 'shorewall::default'
    }
    it 'should install package shorewall' do
      @chef_run.should install_package "shorewall"
    end
    %w{
    /etc/shorewall/hosts
    /etc/shorewall/zones
    /etc/shorewall/interfaces
    /etc/shorewall/policy
    /etc/shorewall/rules
    /etc/shorewall/shorewall.conf

    }.each do |tpl|
      it "should create file #{tpl}" do
        @chef_run.should create_file tpl
      end
    end

    if platform_family == "debian"
      it "should create file /etc/default/shorewall" do
        @chef_run.should create_file "/etc/default/shorewall"
      end
    end
    {
        "/etc/shorewall/zones" => "fw      firewall        -               -                       -\n\nlan     ipv4            -               -                       -",
        "/etc/shorewall/interfaces" => "lan     eth0            -               -",
        "/etc/shorewall/policy" => "fw              all             ACCEPT          -               -\n\nlan             fw              REJECT          -               -\n\nall             all             REJECT          -               -",
        "/etc/shorewall/rules" => "ACCEPT          all             fw              tcp     22      -               -               -               -       -",
        "/etc/shorewall/shorewall.conf" => "STARTUP_ENABLED=Yes"
    }.each do |file, content|
      it "should create file #{file} with specific content" do
        @chef_run.should create_file_with_content(file, content)
      end
    end
    it "should enable and start service shorewall on boot" do
      @chef_run.should set_service_to_start_on_boot "shorewall"
      @chef_run.should start_service "shorewall"
    end
  end
end
