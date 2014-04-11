require "spec_helper"

describe "vara-create-product" do
  def vara_create_product(arguments)
    command = [
      "bundle exec bin/vara-create-product",
      "-v 0.1.0 -m /cassandra_metadata.template",
      "-a aws_access_key -k aws_secret_key"
    ].join(" ")

    out = `#{command} #{arguments}`
    expect($?).to be_success
    yield(out)
  end

  describe "--print flag" do
    it "prints details that will be used when creating the product, does not create the product" do
      vara_create_product "--print --service-type cassandra" do |out|
        expect(out).to include("Service type: cassandra")
      end
    end
  end

  context "when providing a product name explicitly" do
    it "uses it" do
      vara_create_product "--print --service-type cassandra --product-name p-cassandra-dev" do |out|
        expect(out).to include("Product name: p-cassandra-dev")
      end
    end
  end

  context "when not providing a product name" do
    it "uses the service type" do
      vara_create_product "--print --service-type cassandra" do |out|
        expect(out).to include("Product name: p-cassandra")
      end
    end
  end
end
