require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

describe VCloudSdk::VM do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { VCloudSdk::Test::Response::URL }
  let(:disk_name) { VCloudSdk::Test::Response::INDY_DISK_NAME }
  let(:disk) do
    vdc_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::VDC_RESPONSE)

    disk_link = vdc_response
                  .disks(disk_name)
    VCloudSdk::Disk.new(VCloudSdk::Test.mock_session(logger, url),
                        disk_link)
  end

  let(:properties) do
    [
      {
        "type" => "string",
        "key" => "gateway",
        "value" => "10.146.21.253",
        "password" => "false",
        "userConfigurable" => "true",
        "Label" => "Default Gateway",
        "Description" => "The default gateway address for the Pivotal Ops Manager's network. Leave blank if DHCP is desired."
      },
      {
        "type" => "string",
        "key" => "DNS",
        "value" => "10.20.144.1",
        "password" => "false",
        "userConfigurable" => "true",
        "Label" => "DNS",
        "Description" => "The domain name servers for the Pivotal Ops Manager (comma separated). Leave blank if DHCP is desired."
      },
      {
        "type" => "string",
        "key" => "ntp_servers",
        "value" => "10.20.144.1",
        "password" => "false",
        "userConfigurable" => "true",
        "Label" => "NTP Servers",
        "Description" => "Comma-delimited list of NTP servers"
      },
      {
        "type" => "password",
        "key" => "admin_password",
        "value" => "dummy",
        "password" => "false",
        "userConfigurable" => "true",
        "Label" => "Admin Password",
        "Description" => "This password is used to SSH into the Pivotal Ops Manager. The username is 'tempest'."
      },
      {
        "type" => "string",
        "key" => "ip0",
        "value" => "10.146.21.142",
        "password" => "false",
        "userConfigurable" => "true",
        "Label" => "IP Address",
        "Description" => "The IP address for the Pivotal Ops Manager. Leave blank if DHCP is desired."
      },
      {
        "type" => "string",
        "key" => "netmask0",
        "value" => "255.255.255.128",
        "password" => "false",
        "userConfigurable" => "true",
        "Label" => "Netmask",
        "Description" => "The netmask for the Pivotal Ops Manager's network. Leave blank if DHCP is desired."
      }
    ]
  end

  let(:vapp_name) { VCloudSdk::Test::Response::VAPP_NAME }
  let(:vm_name) { VCloudSdk::Test::Response::VM_NAME }
  let(:catalog_name) { VCloudSdk::Test::Response::CATALOG_NAME }
  let(:media_name) { VCloudSdk::Test::Response::EXISTING_MEDIA_NAME }
  let(:network_name) { VCloudSdk::Test::Response::ORG_NETWORK_NAME }

  subject do
    described_class.new(VCloudSdk::Test.mock_session(logger, url),
                        VCloudSdk::Test::Response::INSTANTIATED_VM_LINK)
  end

  describe "#href" do
    it "returns the link of VM" do
      subject.href.should eql VCloudSdk::Test::Response::INSTANTIATED_VM_LINK
    end
  end

  describe "#name" do
    it "returns the name of VM" do
      subject.name.should eql vm_name
    end
  end

  describe "#memory" do
    it "returns memory in megabytes of VM" do
      subject.memory.should eql 32
    end

    context "Allocation Unit is incorrect" do
      it "raises CloudError" do
        subject
          .should_receive(:eval_memory_allocation_units)
          .and_return 1

        expect do
          subject.memory
        end.to raise_exception VCloudSdk::CloudError,
                               "Size of memory is less than 1 MB."
      end
    end
  end

  describe "#memory=" do
    context "input parameter size is negative" do
      it "raises an exception" do
        expect do
          subject.memory = -1
        end.to raise_exception VCloudSdk::CloudError,
                               "Invalid vm memory size -1MB"
      end
    end

    context "change memory with valid parameters" do
      it "change memory successfully" do
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::RECONFIGURE_VM_LINK,
                an_instance_of(VCloudSdk::Xml::Vm),
                VCloudSdk::Xml::MEDIA_TYPE[:VM])
          .and_call_original

        subject
          .should_receive(:monitor_task)
          .with(an_instance_of(VCloudSdk::Xml::Task))
          .and_call_original

        expect do
          subject.memory = 1024
        end.to_not raise_exception
      end
    end

    context "error occurs when changing memory" do
      it "raises the exception" do
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::RECONFIGURE_VM_LINK,
                an_instance_of(VCloudSdk::Xml::Vm),
                VCloudSdk::Xml::MEDIA_TYPE[:VM])
          .and_raise RestClient::BadRequest

        expect do
          subject.memory = 1024
        end.to raise_exception RestClient::BadRequest
      end
    end
  end

  describe "#vcpu" do
    it "returns number of virtual cpus of VM" do
      subject.vcpu.should eql 1
    end

    context "information of number of virtual cpus of VM is unavailable" do
      it "raises CloudError" do
        cpus = double("cpus")
        VCloudSdk::Xml::VirtualHardwareSection
          .any_instance
          .should_receive(:cpu)
          .and_return cpus
        cpus
          .should_receive(:get_rasd_content)
          .with(VCloudSdk::Xml::RASD_TYPES[:VIRTUAL_QUANTITY])
          .and_return nil

        expect do
          subject.vcpu
        end.to raise_exception VCloudSdk::CloudError,
                               "Uable to retrieve number of virtual cpus of VM #{vm_name}"

      end
    end
  end

  describe "#vcpu=" do
    context "input parameter size is negative" do
      it "raises an exception" do
        expect do
          subject.vcpu = -1
        end.to raise_exception VCloudSdk::CloudError,
                               "Invalid virtual CPU count -1"
      end
    end

    context "changes vcpu count with valid parameters" do
      it "changes vcpu count successfully" do
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::RECONFIGURE_VM_LINK,
                an_instance_of(VCloudSdk::Xml::Vm),
                VCloudSdk::Xml::MEDIA_TYPE[:VM])
          .and_call_original

        subject
          .should_receive(:monitor_task)
          .with(an_instance_of(VCloudSdk::Xml::Task))
          .and_call_original

        expect do
          subject.vcpu = 2
        end.to_not raise_exception
      end
    end

    context "error occurs when changing memory" do
      it "raises the exception" do
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::RECONFIGURE_VM_LINK,
                an_instance_of(VCloudSdk::Xml::Vm),
                VCloudSdk::Xml::MEDIA_TYPE[:VM])
          .and_raise RestClient::BadRequest

        expect do
          subject.vcpu = 2
        end.to raise_exception RestClient::BadRequest
      end
    end
  end

  describe "#nics" do
    it "returns a collection of NIC objects" do
      nics = subject.nics
      nics.should have(3).item
      nic = nics[0]
      nic.nic_index.should eql 0
      nic.network.should eql "none"
      nic.is_primary.should be_false
      nic.ip_address.should be_nil
      nic.is_connected.should be_false
      nic.ip_address_allocation_mode.should eql "NONE"
      nic.mac_address.should eql "00:50:56:02:01:cb"
      nic = nics[1]
      nic.nic_index.should eql 1
      nic.network.should eql "none"
      nic.is_primary.should be_true
      nic.ip_address.should eql "10.146.21.151"
      nic.is_connected.should be_true
      nic.ip_address_allocation_mode.should eql "POOL"
      nic.mac_address.should eql "00:50:56:02:00:30"
      nic = nics[2]
      nic.nic_index.should eql 2
      nic.network.should eql "none"
      nic.is_primary.should be_false
      nic.ip_address.should be_nil
      nic.is_connected.should be_true
      nic.ip_address_allocation_mode.should eql "DHCP"
      nic.mac_address.should eql "00:50:56:02:00:2f"
    end
  end

  describe "#eval_memory_allocation_units" do
    it "returns allocation_units in number of bytes" do
      bytes = ["byte*3*2^20", "byte * 2^20", "byte * 2^10", "byte"].map do |allocation_units|
        subject
          .send(:eval_memory_allocation_units, allocation_units)
      end

      bytes.should eql [3 * 1024 * 1024, 1024 * 1024, 1024, 1]
    end

    context "allocation_units is in invalid form" do
      it "raises ApiError" do
        expect do
          subject
            .send(:eval_memory_allocation_units, "bit * 2^20")
        end.to raise_exception VCloudSdk::ApiError,
                               "Unexpected form of AllocationUnits of memory: 'bit * 2^20'"
      end
    end
  end

  describe "#independent_disks" do
    context "vm has attached disk" do
      it "returns a collection of disks" do
        VCloudSdk::Test::ResponseMapping.set_option vm_disk_attached: true
        disks = subject.independent_disks
        disks.should have(1).item
        disk = disks[0]
        disk.should be_an_instance_of VCloudSdk::Disk
        disk.name.should eql disk_name
      end
    end

    context "vm has no attached disk" do
      before do
        VCloudSdk::Test::ResponseMapping.delete_option :vm_disk_attached
      end

      its(:independent_disks) { should eql [] }
    end
  end

  describe "#create_internal_disk" do
    context "input parameter size is negative" do
      it "raises an exception" do
        expect do
          subject.create_internal_disk(-1)
        end.to raise_exception VCloudSdk::CloudError,
                               "Invalid size in MB -1"
      end
    end

    context "bus_type specified is invalid" do
      it "raises an error" do
        expect do
          subject.create_internal_disk(100, "xxx", "lsilogic")
        end.to raise_exception VCloudSdk::CloudError,
                               "Invalid bus type!"
      end
    end

    context "bus_sub_type specified is invalid" do
      it "raises an error" do
        expect do
          subject.create_internal_disk(100, "scsi", "xxx")
        end.to raise_exception VCloudSdk::CloudError,
                               "Invalid bus sub type!"
      end
    end

    context "create disk with valid parameters" do
      it "creates an independent disk successfully" do
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::RECONFIGURE_VM_LINK,
                an_instance_of(VCloudSdk::Xml::Vm),
                VCloudSdk::Xml::MEDIA_TYPE[:VM])
          .and_call_original

        subject
          .should_receive(:monitor_task)
          .with(an_instance_of(VCloudSdk::Xml::Task))
          .and_call_original

        expect do
          subject.create_internal_disk(100)
        end.to_not raise_exception
      end
    end

    context "bus_type and bus_sub_type are specified" do
      it "creates an independent disk successfully" do
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::RECONFIGURE_VM_LINK,
                an_instance_of(VCloudSdk::Xml::Vm),
                VCloudSdk::Xml::MEDIA_TYPE[:VM])
          .and_call_original

        subject
          .should_receive(:monitor_task)
          .with(an_instance_of(VCloudSdk::Xml::Task))
          .and_call_original

        expect do
          subject.create_internal_disk(100)
        end.to_not raise_exception
      end
    end
  end

  describe "#delete_internal_disk_by_name" do
    context "the given disk is not found" do
      it "raises an exception" do
        expect do
          subject.delete_internal_disk_by_name("Invalid disk name")
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "Internal disk 'Invalid disk name' is not found"
      end
    end

    context "deletes disk with valid parameters" do
      it "deletes the disk successfully" do
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::RECONFIGURE_VM_LINK,
                an_instance_of(VCloudSdk::Xml::Vm),
                VCloudSdk::Xml::MEDIA_TYPE[:VM])
          .and_call_original

        subject
          .should_receive(:monitor_task)
          .with(an_instance_of(VCloudSdk::Xml::Task))
          .and_call_original

        expect do
          subject.delete_internal_disk_by_name("Hard disk 1")
        end.to_not raise_exception
      end
    end
  end

  describe "#internal_disks" do
    context "vm has internal disk(s)" do
      it "returns disk(s)" do
        disks = subject.internal_disks
        disks.should have_at_least(1).item
        disk = disks[0]
        disk.should be_an_instance_of VCloudSdk::InternalDisk
        disk.capacity.should eql 200
        disk.name.should eql "Hard disk 1"
      end
    end
  end

  describe "#list_disks" do
    context "vm has attached disk" do
      before do
        VCloudSdk::Test::ResponseMapping.set_option vm_disk_attached: true
      end

      its(:list_disks) { should eql ["Hard disk 1", "Hard disk 2 (#{disk_name})"] }
    end

    context "vm has no attached disk" do
      before do
        VCloudSdk::Test::ResponseMapping.delete_option :vm_disk_attached
      end

      its(:list_disks) { should eql ["Hard disk 1"] }
    end
  end

  describe "#attach_disk" do
    context "the disk is already attached to VM" do
      it "raises an error" do
        VCloudSdk::Test::ResponseMapping
          .set_option disk_state: :attached
        expect do
          subject.attach_disk(disk)
        end.to raise_exception VCloudSdk::CloudError,
                               "Disk '#{disk.name}' of link #{disk.href} is attached to VM '#{disk.vm.name}'"
      end
    end

    context "the disk is not attached to any VM" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option disk_state: :not_attached
      end

      it "attaches the disk successfully" do
        subject
          .send(:connection)
          .should_receive(:post)
          .once
          .with(VCloudSdk::Test::Response::INSTANTIATED_VM_ATTACH_DISK_LINK,
                anything,
                VCloudSdk::Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
          .and_call_original

        subject
          .should_receive(:monitor_task)
          .with(an_instance_of(VCloudSdk::Xml::Task))
          .and_call_original

        expect do
          subject.attach_disk(disk)
        end.to_not raise_exception
      end

      context "error occurs when attaching disk" do

        it "raises the exception" do
          subject
            .send(:connection)
            .should_receive(:post)
            .once
            .with(VCloudSdk::Test::Response::INSTANTIATED_VM_ATTACH_DISK_LINK,
                  anything,
                  VCloudSdk::Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
            .and_raise RestClient::BadRequest

          expect do
            subject.attach_disk(disk)
          end.to raise_exception RestClient::BadRequest
        end
      end
    end
  end

  describe "#detach_disk" do
    context "vApp is suspended" do
      it "raises VmSuspendedError" do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :suspended

        expect do
          subject.detach_disk(disk)
        end.to raise_exception VCloudSdk::VmSuspendedError,
                               "vApp #{VCloudSdk::Test::Response::VAPP_NAME}" +
                               " suspended, discard state before detaching disk."
      end
    end

    context "vApp is powered on" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :on
      end

      context "the disk is not attached to any VM" do
        it "raises an error" do
          VCloudSdk::Test::ResponseMapping
            .set_option disk_state: :not_attached

          expect do
            subject.detach_disk(disk)
          end.to raise_exception VCloudSdk::CloudError,
                                 "No vm is attached to disk '#{disk.name}'"
        end
      end

      context "the disk is attached to other VM" do
        it "raises an error" do
          VCloudSdk::Test::ResponseMapping
            .set_option disk_state: :attached

          other_vm = double("other VM")
          other_vm
            .stub(:name) { "other VM" }
          other_vm
            .stub(:href) { "other vm link" }

          disk
            .should_receive(:vm)
            .and_return other_vm

          expect do
            subject.detach_disk(disk)
          end.to raise_exception VCloudSdk::CloudError,
                                 "Disk '#{disk.name}' is attached to other VM - name: 'other VM', link 'other vm link'"
        end
      end

      context "the disk is attached to current VM" do
        before do
          VCloudSdk::Test::ResponseMapping
            .set_option disk_state: :attached
        end

        it "detaches the disk successfully" do
          subject
            .send(:connection)
            .should_receive(:post)
            .once
            .with(VCloudSdk::Test::Response::INSTANTIATED_VM_DETACH_DISK_LINK,
                  anything,
                  VCloudSdk::Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
            .and_call_original

          subject
            .should_receive(:monitor_task)
            .with(an_instance_of(VCloudSdk::Xml::Task))
            .and_call_original

          expect do
            subject.detach_disk(disk)
          end.to_not raise_exception
        end

        context "error occurs when attaching disk" do
          it "raises the exception" do
            subject
              .send(:connection)
              .should_receive(:post)
              .once
              .with(VCloudSdk::Test::Response::INSTANTIATED_VM_DETACH_DISK_LINK,
                    anything,
                    VCloudSdk::Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
              .and_raise RestClient::BadRequest

            expect do
              subject.detach_disk(disk)
            end.to raise_exception RestClient::BadRequest
          end
        end
      end
    end
  end

  describe "#status" do
    context "VM is powered on" do
      it "returns status POWERED_ON" do
        VCloudSdk::Xml::Vm
          .any_instance
          .stub(:[])
          .with(:status) { "4" }
        subject.status.should eql "POWERED_ON"
      end
    end

    context "VM is powered off" do
      it "returns the status POWERED_OFF" do
        VCloudSdk::Xml::Vm
          .any_instance
          .stub(:[])
          .with(:status) { "8" }
        subject.status.should eql "POWERED_OFF"
      end
    end

    context "VM is suspended" do
      it "returns the status SUSPENDED" do
        VCloudSdk::Xml::Vm
          .any_instance
          .stub(:[])
          .with(:status) { "3" }
        subject.status.should eql "SUSPENDED"
      end
    end
  end

  describe "#power_on" do
    context "VM is powered off" do
      before do
        VCloudSdk::Xml::Vm
          .any_instance
          .stub(:[])
          .with(:status) { "8" }
      end

      it "powers on target VM successfully" do
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::INSTANTIATED_VM_POWER_ON_LINK,
                nil)
          .and_call_original
        result = subject.power_on
        result.should be_an_instance_of(VCloudSdk::VM)
      end

      context "request to power on VM times out" do
        it "fails to power on VM" do
          subject
            .should_receive(:task_is_success)
            .at_least(3)
            .and_return(false)

          expect { subject.power_on }
          .to raise_exception VCloudSdk::ApiTimeoutError,
                              "Task Starting Virtual Machine sc-1f9f883e-968c-4bad-88e3-e7cb36881788(b2ee6bb6-d70f-4c54-8789-c2fd123c6491)" +
                              " did not complete within limit of 3 seconds."
        end
      end
    end

    context "VM is powered on" do
      before do
        VCloudSdk::Xml::Vm
          .any_instance
          .stub(:[])
          .with(:status) { "4" }
      end

      it "does not try to power on VM again" do
        subject.send(:connection)
          .should_not_receive(:post)

        subject.power_on
      end
    end
  end

  describe "#power_off" do

    context "VM is powered on" do
      before do
        VCloudSdk::Xml::Vm
          .any_instance
          .stub(:[])
          .with(:status) { "4" }
      end

      it "powers off target VM successfully" do
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::INSTANTIATED_VM_POWER_OFF_LINK,
                nil)
          .and_call_original
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::INSTANTIATED_VM_UNDEPLOY_LINK,
              an_instance_of(VCloudSdk::Xml::Wrapper))
          .and_call_original
        result = subject.power_off
        result.should be_an_instance_of(VCloudSdk::VM)
      end

      context "request to power off VM times out" do
        it "fails to power off VM" do
          subject
            .should_receive(:task_is_success)
            .at_least(3)
            .and_return(false)

          expect { subject.power_off }
          .to raise_exception VCloudSdk::ApiTimeoutError,
                              "Task Starting Virtual Machine sc-1f9f883e-968c-4bad-88e3-e7cb36881788(b2ee6bb6-d70f-4c54-8789-c2fd123c6491)" +
                              " did not complete within limit of 3 seconds."
        end
      end
    end

    context "VM is powered off" do
      before do
        VCloudSdk::Xml::Vm
          .any_instance
          .stub(:[])
          .with(:status) { "8" }
      end

      it "does not try to power off the VM again" do
        subject
          .send(:connection)
          .should_not_receive(:post)

        subject.power_off
      end
    end

    context "VM is suspended" do
      before do
        VCloudSdk::Xml::Vm
          .any_instance
          .stub(:[])
          .with(:status) { "3" }
      end

      it "raises an error" do
        subject
          .send(:connection)
          .should_not_receive(:post)

        expect { subject.power_off }
        .to raise_exception VCloudSdk::VmSuspendedError,
                            "VM #{vm_name} suspended, discard state before powering off."
      end
    end
  end

  describe "#insert_media" do
    context "catalog containing media file does not exist" do
      it "raises ObjectNotFoundError" do
        expect do
          subject.insert_media("dummy", "dummy")
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "Catalog 'dummy' is not found"
      end
    end

    context "catalog containing media file exists" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option catalog_state: :added
      end

      context "media file matching the name does not exist" do
        it "raises ObjectNotFoundError" do
          expect do
            subject.insert_media(catalog_name, "dummy")
          end.to raise_exception VCloudSdk::ObjectNotFoundError,
                                 "Catalog Item 'dummy' is not found"
        end
      end

      context "media file matching the name exists" do
        before do
          VCloudSdk::Test::ResponseMapping
            .set_option existing_media_state: :done
        end

        context "media file has a running task" do
          it "inserts media file successfully" do
            VCloudSdk::Test::ResponseMapping
              .set_option existing_media_state: :busy

            subject
              .send(:connection)
              .should_receive(:post)
              .with(VCloudSdk::Test::Response::INSTANTIATED_VM_INSERT_MEDIA_LINK,
                    anything,
                    VCloudSdk::Xml::MEDIA_TYPE[:MEDIA_INSERT_EJECT_PARAMS])
              .and_call_original

            subject
              .should_receive(:monitor_task)
              .twice
              .with(an_instance_of(VCloudSdk::Xml::Task))
              .and_call_original

            expect do
              subject.insert_media(catalog_name, media_name)
            end.to_not raise_exception
          end
        end

        context "media file has no running task" do
          it "inserts media file successfully" do
            subject
              .send(:connection)
              .should_receive(:post)
              .with(VCloudSdk::Test::Response::INSTANTIATED_VM_INSERT_MEDIA_LINK,
                    anything,
                    VCloudSdk::Xml::MEDIA_TYPE[:MEDIA_INSERT_EJECT_PARAMS])
              .and_call_original

            subject
              .should_receive(:monitor_task)
              .with(an_instance_of(VCloudSdk::Xml::Task))
              .and_call_original

            expect do
              subject.insert_media(catalog_name, media_name)
            end.to_not raise_exception
          end
        end

        context "error occurs when inserting media" do
          it "raises the exception" do
            subject
              .send(:connection)
              .should_receive(:post)
              .once
              .with(VCloudSdk::Test::Response::INSTANTIATED_VM_INSERT_MEDIA_LINK,
                    anything,
                    VCloudSdk::Xml::MEDIA_TYPE[:MEDIA_INSERT_EJECT_PARAMS])
              .and_raise RestClient::BadRequest

            expect do
              subject.insert_media(catalog_name,
                                   media_name)
            end.to raise_exception RestClient::BadRequest
          end
        end
      end
    end
  end

  describe "#eject_media" do
    context "catalog containing media file does not exist" do
      it "raises ObjectNotFoundError" do
        expect do
          subject.eject_media("dummy", "dummy")
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "Catalog 'dummy' is not found"
      end
    end

    context "catalog containing media file exists" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option catalog_state: :added
      end

      context "media file matching the name does not exist" do
        it "raises ObjectNotFoundError" do
          expect do
            subject.eject_media(catalog_name, "dummy")
          end.to raise_exception VCloudSdk::ObjectNotFoundError,
                                 "Catalog Item 'dummy' is not found"
        end
      end

      context "media file matching the name exists" do
        before do
          VCloudSdk::Test::ResponseMapping
            .set_option existing_media_state: :done
        end

        context "media file has a running task" do
          it "ejects media file successfully" do
            VCloudSdk::Test::ResponseMapping
              .set_option existing_media_state: :busy

            subject
              .send(:connection)
              .should_receive(:post)
              .once
              .with(VCloudSdk::Test::Response::INSTANTIATED_VM_EJECT_MEDIA_LINK,
                    anything,
                    VCloudSdk::Xml::MEDIA_TYPE[:MEDIA_INSERT_EJECT_PARAMS])
              .and_call_original

            subject
              .should_receive(:monitor_task)
              .twice
              .with(an_instance_of(VCloudSdk::Xml::Task))
              .and_call_original

            expect do
              subject.eject_media(catalog_name, media_name)
            end.to_not raise_exception
          end
        end

        context "media file has no running task" do
          it "ejects media file successfully" do
            subject
              .send(:connection)
              .should_receive(:post)
              .once
              .with(VCloudSdk::Test::Response::INSTANTIATED_VM_EJECT_MEDIA_LINK,
                    anything,
                    VCloudSdk::Xml::MEDIA_TYPE[:MEDIA_INSERT_EJECT_PARAMS])
              .and_call_original

            subject
              .should_receive(:monitor_task)
              .with(an_instance_of(VCloudSdk::Xml::Task))
              .and_call_original

            expect do
              subject.eject_media(catalog_name, media_name)
            end.to_not raise_exception
          end
        end

        context "error occurs when ejecting media" do
          it "raises the exception" do
            subject
              .send(:connection)
              .should_receive(:post)
              .once
              .with(VCloudSdk::Test::Response::INSTANTIATED_VM_EJECT_MEDIA_LINK,
                    anything,
                    VCloudSdk::Xml::MEDIA_TYPE[:MEDIA_INSERT_EJECT_PARAMS])
              .and_raise RestClient::BadRequest

            expect do
              subject.eject_media(catalog_name,
                                  media_name)
            end.to raise_exception RestClient::BadRequest
          end
        end
      end
    end
  end

  describe "#add_nic" do
    before do
      VCloudSdk::Test::ResponseMapping
        .set_option vapp_power_state: :off
    end

    it "adds nic to VM" do
      subject
        .send(:connection)
        .should_receive(:post)
        .with(VCloudSdk::Test::Response::RECONFIGURE_VM_LINK,
              an_instance_of(VCloudSdk::Xml::Vm),
              VCloudSdk::Xml::MEDIA_TYPE[:VM])
        .and_call_original

      subject
        .should_receive(:monitor_task)
        .with(an_instance_of(VCloudSdk::Xml::Task))
        .and_call_original

      expect do
        subject.add_nic(network_name)
      end.to_not raise_exception
    end

    context "ip_addressing_mode is invalid" do
      it "raises CloudError" do
        expect do
          subject.add_nic(network_name, "dummy")
        end.to raise_exception VCloudSdk::CloudError,
                               "Invalid IP_ADDRESSING_MODE 'dummy'"
      end
    end

    context "ip is not specified in 'MANUAL' ip_addressing_mode" do
      it "raises CloudError" do
        expect do
          subject.add_nic(network_name, "MANUAL")
        end.to raise_exception VCloudSdk::CloudError,
                               "IP is missing for MANUAL IP_ADDRESSING_MODE"
      end
    end

    context "VM is powered on" do
      it "raises CloudError" do
        subject
          .should_receive(:is_status?)
          .with(anything, :POWERED_ON)
          .and_return true
        expect do
          subject.add_nic(network_name)
        end.to raise_exception VCloudSdk::CloudError,
                               "VM #{vm_name} is powered-on and cannot add NIC."
      end
    end

    context "Network is not added to VApp" do
      it "raises CloudError" do
        expect do
          subject.add_nic("dummy")
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "Network dummy is not added to parent VApp #{vapp_name}"
      end
    end

  end

  describe "#delete_nics" do
    before do
      VCloudSdk::Test::ResponseMapping
        .set_option vapp_power_state: :off
    end

    context "delete one nic" do
      it "deletes nic from VM" do
        nic = double("nic")
        nic.should_receive(:nic_index) { 1 }
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::RECONFIGURE_VM_LINK,
                vm_nic_indexes([0,2]),
                VCloudSdk::Xml::MEDIA_TYPE[:VM])
          .and_call_original
        result = subject.delete_nics(nic)
        result.should be_an_instance_of(VCloudSdk::VM)
      end
    end

    context "delete two nics" do
      it "deletes nic from VM" do
        nic1 = double("nic1")
        nic1.should_receive(:nic_index) { 1 }
        nic2 = double("nic2")
        nic2.should_receive(:nic_index) { 2 }
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::RECONFIGURE_VM_LINK,
                vm_nic_indexes([0]),
                VCloudSdk::Xml::MEDIA_TYPE[:VM])
          .and_call_original
        result = subject.delete_nics(nic1, nic2)
        result.should be_an_instance_of(VCloudSdk::VM)
      end
    end

    context "delete three nics" do
      it "deletes nic from VM" do
        nic0 = double("nic0")
        nic0.should_receive(:nic_index) { 0 }
        nic1 = double("nic1")
        nic1.should_receive(:nic_index) { 1 }
        nic2 = double("nic2")
        nic2.should_receive(:nic_index) { 2 }
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::RECONFIGURE_VM_LINK,
                vm_nic_indexes([]),
                VCloudSdk::Xml::MEDIA_TYPE[:VM])
          .and_call_original
        result = subject.delete_nics(nic0, nic1, nic2)
        result.should be_an_instance_of(VCloudSdk::VM)
      end
    end

    context "VM is powered on" do
      it "raises CloudError" do
        subject
          .should_receive(:is_status?)
          .with(anything, :POWERED_ON)
          .and_return true
        expect do
          subject.delete_nics(double("nic"))
        end.to raise_exception VCloudSdk::CloudError,
                               "VM #{vm_name} is powered-on and cannot delete NIC."
      end
    end

  end

  describe "#product_section_properties" do
    it "returns array of hash values representing properties of product section of VM" do
      subject.product_section_properties.should eql properties
    end

    context "VM does not have product section" do
      it "returns empty array" do
        subject.stub_chain("entity_xml.product_section")
        subject.product_section_properties.should eql []
      end
    end
  end

  describe "#product_section_properties=" do
    it "updates product section of VM" do
      subject
        .send(:connection)
        .should_receive(:put)
        .with(VCloudSdk::Test::Response::INSTANTIATED_VM_PRODUCT_SECTION_LINK,
              an_instance_of(VCloudSdk::Xml::ProductSectionList),
              VCloudSdk::Xml::MEDIA_TYPE[:PRODUCT_SECTIONS])
        .and_call_original

      subject
        .should_receive(:monitor_task)
        .with(an_instance_of(VCloudSdk::Xml::Task))
        .and_call_original

      expect do
        subject.product_section_properties = properties
      end.to_not raise_exception
    end

    context "error occurs when updating product section" do
      it "raises the exception" do
        subject
          .send(:connection)
          .stub(:put)
          .with(VCloudSdk::Test::Response::INSTANTIATED_VM_PRODUCT_SECTION_LINK,
                an_instance_of(VCloudSdk::Xml::ProductSectionList),
                VCloudSdk::Xml::MEDIA_TYPE[:PRODUCT_SECTIONS])
          .and_raise RestClient::BadRequest

        expect do
          subject.product_section_properties = properties
        end.to raise_exception RestClient::BadRequest
      end
    end
  end
end

module RSpec
  module Mocks
    module ArgumentMatchers
      class VMNICIndexesMatcher
        def initialize(nic_indexes)
          @nic_indexes = nic_indexes
        end

        def ==(other)
          other.instance_of?(VCloudSdk::Xml::Vm) &&
          @nic_indexes == other.network_connection_section
                               .network_connections
                               .map { |n| n.network_connection_index.to_i }
                               .sort
        end

        def description
          "Check VM NIC indexes"
        end
      end

      def vm_nic_indexes(nic_indexes)
        VMNICIndexesMatcher.new(nic_indexes)
      end
    end
  end
end
