require "ruby_vcloud_sdk/ip_ranges"
require "set"

describe VCloudSdk::IpRanges do

  share_examples_for "VCloudSdk::IpRanges" do |ip_range_string, n|
    it "parses input string[#{ip_range_string}] correctly" do
      ip_range = described_class.new(ip_range_string).ranges
      ip_range.should be_an_instance_of Set
      ip_range.should have(n).item
      ip_range.each do |i|
        i.should be_an_instance_of String
      end
    end
  end

  describe "#initialize" do
    context "valid input string" do
      context "a single IP address" do
        it_should_behave_like "VCloudSdk::IpRanges", "10.142.15.11", 1
      end

      context "input string uses '-' separator" do
        it_should_behave_like "VCloudSdk::IpRanges",
                              "10.142.15.11-10.142.15.22",
                              12
      end

      context "input string uses subnet mask" do
        it_should_behave_like "VCloudSdk::IpRanges",
                              "10.142.15.0/24",
                              256
      end

      context "input string uses comma separated IPs" do
        it_should_behave_like "VCloudSdk::IpRanges",
                              "10.142.15.0,10.142.15.4,10.142.16.4",
                              3
        it_should_behave_like "VCloudSdk::IpRanges",
                              "10.142.15.11-10.142.15.22,10.142.2.4,10.142.16.4/23",
                              525
      end
    end

    context "invalid input" do
      context "not a string" do
        it "raises an error" do
          expect { described_class.new(["XX"]) }
            .to raise_exception "Parameter is not a string"
        end
      end

      context "invalid string" do
        it "raises an error" do
          expect { described_class.new("XX") }
            .to raise_exception NetAddr::ValidationError,
                                "Could not auto-detect IP version for 'XX'."
        end
      end

      context "Invalid IP address" do
        it "raises an error" do
          ip_range_string = "10.1.142.256"
          expect { described_class.new(ip_range_string) }
            .to raise_exception NetAddr::ValidationError
          ip_range_string = "10.1.142.252 - 10.1.142.256"
          expect { described_class.new(ip_range_string) }
            .to raise_exception NetAddr::ValidationError
        end
      end

      context "Incorrect separator" do
        it "raises an error" do
          ip_range_string = "10.1.142.255 - "
          expect { described_class.new(ip_range_string) }
            .to raise_exception "Invalid input: 1 field/fields separated by '-'"
          ip_range_string = "10.1.142.255 - 10.1.142.2 - 10.1.142.3"
          expect { described_class.new(ip_range_string) }
            .to raise_exception "Invalid input: 3 field/fields separated by '-'"
          ip_range_string = "10.1.142.252/"
          expect { described_class.new(ip_range_string) }
            .to raise_exception ArgumentError,
                                "CIDR address is improperly formatted. Missing netmask after '/' character."
        end
      end

      context "start address is bigger than end address" do
        it "raises an error" do
          ip_range_string = "10.1.142.255 - 10.1.142.1"
          expect { described_class.new(ip_range_string) }
            .to raise_error \
              "IP 10.1.142.255 is bigger than IP 10.1.142.1"
        end
      end

      context "bad subnet mask" do
        it "raises an error" do
          ip_range_string = "10.1.142.0/33"
          expect { described_class.new(ip_range_string) }
            .to raise_error NetAddr::ValidationError,
                            "Netmask, 33, is out of bounds for IPv4."
        end
      end

      context "IPv6 is used" do
        it "raises an error" do
          expect { described_class.new("fec0::/64") }
            .to raise_error "IPv6 is not supported"
        end
      end
    end
  end

  describe "#include?" do
    subject { described_class.new("10.142.15.11 - 10.142.15.22") }

    context "target range is included" do
      it "returns true" do
        ip_range = "10.142.15.11"
        subject.include?(ip_range).should be_true

        ip_range = "10.142.15.11, 10.142.15.12"
        subject.include?(ip_range).should be_true

        ip_range = "10.142.15.19 - 10.142.15.22"
        subject.include?(ip_range).should be_true

        ip_range = "10.142.15.19/31"
        subject.include?(ip_range).should be_true
      end
    end

    context "target range is not included" do
      it "returns false" do
        ip_range = "10.142.15.09, 10.142.15.12"
        subject.include?(ip_range).should be_false

        ip_range = "10.142.15.19 - 10.142.15.25"
        subject.include?(ip_range).should be_false

        ip_range = "10.142.15.19/25"
        subject.include?(ip_range).should be_false
      end
    end
  end

  describe "#add" do
    subject { described_class.new }

    context "when target object is empty" do
      it "adds new range" do
        result = described_class.new("10.0.0.1-10.0.0.10").ranges
        (subject + "10.0.0.1-10.0.0.10").ranges.should eql result
      end
    end

    context "when target object is not empty" do
      let(:ranges) do
        ["10.0.0.1-10.0.0.10",
         "10.0.0.30-10.0.0.40",
         "10.0.0.50-10.0.0.55"]
      end

      subject { described_class.new(ranges[0..1].join(",")) }
      it "adds new range" do
        result = described_class.new(ranges[0..2].join(",")).ranges
        (subject + "10.0.0.50-10.0.0.55").ranges.should eql result
      end

      it "merges new range with existing range" do
        result =
          described_class.new("10.0.0.1-10.0.0.10,10.0.0.30-10.0.0.55").ranges
        (subject + "10.0.0.35-10.0.0.55").ranges.should eql result
      end
    end

    context "Not an IpRange or string type to add" do
      it "raises an error" do
        expect { subject.add([]) }
        .to raise_exception "Unable to parse object that is not IpRange or string"
      end
    end
  end

  describe "#subtract" do
    context "when there is no overlap" do
      let(:minuend_one) { described_class.new("10.0.0.11-10.0.0.21") }
      let(:subtrahend_one) { "10.0.0.22-10.0.0.25" }
      let(:minuend_multi) do
        described_class.new("10.0.0.11-10.0.0.21,10.0.0.31-10.0.0.41")
      end
      let(:subtrahend_multi) do
        "10.0.0.22-10.0.0.25,10.0.0.42-10.0.0.45"
      end

      context "with minuend 1 range and subtrahend 1 range" do
        it "returns range equivalent to the minuend" do
          (minuend_one - subtrahend_one).ranges.should eql minuend_one.ranges
        end
      end

      context "with minuend multiple ranges and subtrahend 1 range" do
        it "returns range equivalent to the minuend" do
          (minuend_multi - subtrahend_one)
            .ranges.should eql minuend_multi.ranges
        end
      end

      context "with minuend 1 range and subtrahend multiple ranges" do
        it "returns range equivalent to the minuend" do
          (minuend_one - subtrahend_multi)
            .ranges.should eql minuend_one.ranges
        end
      end

      context "with minuend multiple ranges and subtrahend multiple ranges" do
        it "returns range equivalent to the minuend" do
          (minuend_multi - subtrahend_multi)
            .ranges.should eql minuend_multi.ranges
        end
      end
    end

    context "when there is overlap" do
      context "when minuend fully contained in subtrahend" do
        let(:minuend_data) do
          ["10.0.0.1-10.0.0.5",
           "10.0.0.7-10.0.0.9",
           "10.0.0.22-10.0.0.25",
           "10.0.0.40-10.0.0.50"]
        end

        let(:subtrahend_data) do
          ["10.0.0.1-10.0.0.10",
           "10.0.0.20-10.0.0.30",
           "10.0.0.35-10.0.0.45",
           "10.0.0.46-10.0.0.55"]
        end

        let(:minuend_one) { described_class.new(minuend_data[0]) }
        let(:subtrahend_one) { subtrahend_data[0] }
        let(:minuend_multi) { described_class.new(minuend_data.join(",")) }
        let(:subtrahend_multi) { subtrahend_data.join(",") }
        let(:empty_set) { Set.new }

        context "with minuend 1 range and subtrahend 1 range" do
          it "returns empty range object" do
            (minuend_one - subtrahend_one)
              .ranges.should eql empty_set
          end
        end

        context "with minuend 1 range and subtrahend multiple ranges" do
          it "returns empty range object" do
            (minuend_one - subtrahend_multi)
              .ranges.should eql empty_set
          end
        end

        context "with minuend multiple ranges and subtrahend 1 range" do
          let(:minuend_multi) { described_class.new(minuend_data[0..1].join(",")) }
          it "returns empty range object" do
            (minuend_multi - subtrahend_one)
              .ranges.should eql empty_set
          end
        end

        context "with minuend multiple ranges and subtrahend multiple ranges" do
          it "returns empty range object" do
            (minuend_one - subtrahend_one)
              .ranges.should eql empty_set
          end
        end
      end

      context "when minuend is partially contained in subtrahend" do
        let(:minuend_data) do
          ["10.0.0.1-10.0.0.10",
           "10.0.0.30-10.0.0.40"]
        end

        let(:subtrahend_data) do
          ["10.0.0.5-10.0.0.7",
           "10.0.0.9-10.0.0.12",
           "10.0.0.25-10.0.0.35"]
        end

        context "with minuend and subtrahend single ranges" do
          let(:minuend) { described_class.new(minuend_data[0]) }
          let(:subtrahend) { described_class.new(subtrahend_data[0]) }
          it "returns the difference" do
            result = described_class
                       .new("10.0.0.1-10.0.0.4,10.0.0.8-10.0.0.10")
            (minuend - subtrahend)
              .ranges.should eql result.ranges
          end
        end

        context "with minuend and subtrahend multiple ranges" do
          let(:minuend) { described_class.new(minuend_data.join(",")) }
          let(:subtrahend) { described_class.new(subtrahend_data.join(",")) }
          it "returns the difference" do
            result_data = [
              "10.0.0.1-10.0.0.4",
              "10.0.0.8-10.0.0.8",
              "10.0.0.36-10.0.0.40",
            ]
            result = described_class.new(result_data.join(","))
            (minuend - subtrahend)
              .ranges.should eql result.ranges
          end
        end
      end
    end
  end
end
