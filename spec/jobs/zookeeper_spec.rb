require 'rspec'
require 'json'
require 'yaml' # todo fix bosh-template
require 'bosh/template/test'

describe 'zookeeper job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('zookeeper') }

  describe "zookeeper config template" do
    let(:template) { job.template("config/zoo.cfg") }
    let(:zookeeper_link) {
      Bosh::Template::Test::Link.new(
        name: 'peers',
        instances: [Bosh::Template::Test::LinkInstance.new()],
        properties: {
          "quorum_port" => 1,
          "leader_election_port" => 2,
          "client_port" => 3
        }
      )
    }

    let(:links) {
      [zookeeper_link]
    }
    
    describe "with default manifest values" do
      it "renders properly" do
        expect { template.render({}, consumes: links) }.not_to raise_error
      end
    end

    describe "using custom data dirs" do
      let(:manifest) {
        {
          "data_dir" => '/a',
          "data_log_dir" => '/b'
        }
      }
      it "renders properly" do
        expect { template.render(manifest, consumes: links) }.not_to raise_error
      end

      it "sets the az to the one the instance uses" do
        expect(template.render(manifest, consumes: links)).to include("dataDir=/a")
        expect(template.render(manifest, consumes: links)).to include("dataLogDir=/b")
      end
    end

    describe "zookeeper post-stop template" do
      let(:template) { job.template("bin/post-stop") }
      let(:zookeeper_link) {
        Bosh::Template::Test::Link.new(
          name: 'peers',
          instances: [Bosh::Template::Test::LinkInstance.new()],
          properties: {
            "quorum_port" => 1,
            "leader_election_port" => 2,
            "client_port" => 3
          }
        )
      }
  
      let(:links) {
        [zookeeper_link]
      }
      
      describe "with default manifest values" do
        it "renders properly" do
          expect { template.render({}, consumes: links) }.not_to raise_error
          expect(template.render(manifest, consumes: links)).to_not include("export BACKUP_TRANS_LOG_DIR")
        end
      end
  
      describe "using custom data dirs" do
        let(:manifest) {
          {
            "data_dir" => '/a',
            "data_log_dir" => '/b',
            "transaction_logs_backup" => true
          }
        }
        it "renders properly" do
          expect { template.render(manifest, consumes: links) }.not_to raise_error
        end
  
        it "sets the az to the one the instance uses" do
          expect(template.render(manifest, consumes: links)).to include("dataDir=/a")
          expect(template.render(manifest, consumes: links)).to include("dataLogDir=/b")
        end
      end
    end

    # describe "using indexing and spacing" do
    #   let(:manifest) {
    #     {  
    #       "starting_index" => "3",
    #       "index_spacing" => "2"
    #     }
    #   }

    #   let(:instance_2) { Bosh::Template::Test::InstanceSpec.new(name:'zookeeper', az: 'az3', bootstrap: false, index: 2) }

    #   it "renders properly" do
    #     expect { template.render(manifest, consumes: links) }.not_to raise_error
    #   end

    #   it "sets broker id based on starting index provided" do
    #     expect(template.render(manifest, consumes: links)).to include("broker.id=3")
    #   end

    #   it "sets broker id for third instance based on starting index provided" do
    #     expect(template.render(manifest, spec: instance_2, consumes: links)).to include("broker.id=7")
    #   end
    # end
  end
end