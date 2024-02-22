# frozen_string_literal: true

RSpec.describe ReverseEtl::Transformers::UserMapping do
  describe "#transform" do
    let(:extractor) { ReverseEtl::Transformers::UserMapping.new }

    context "with complex mapping including arrays and nested structures" do
      let(:sync) { instance_double("Sync", configuration: mapping) }
      let(:sync_record) { instance_double("SyncRecord", record: source_data) }
      let(:mapping) do
        { "cr_fee" => "attributes.properties.fee", "cr_item_sk" => "id" }
      end

      let(:source_data) do
        { "cr_fee" => "57.82",
          "cr_item_sk" => "231891",
          "cr_net_loss" => "147.53",
          "cr_reason_sk" => "40",
          "cr_return_tax" => "2.33",
          "cr_order_number" => "14551370779",
          "cr_ship_mode_sk" => "5",
          "cr_store_credit" => "8.71",
          "cr_warehouse_sk" => "1",
          "cr_refunded_cash" => "62.15",
          "cr_return_amount" => "77.69",
          "cr_call_center_sk" => "54",
          "cr_catalog_page_sk" => "34956",
          "cr_return_quantity" => "17",
          "cr_reversed_charge" => "6.83",
          "cr_refunded_addr_sk" => "20717265",
          "cr_return_ship_cost" => "87.38",
          "cr_returned_date_sk" => "2452743",
          "cr_returned_time_sk" => "72108",
          "cr_refunded_cdemo_sk" => "1515291",
          "cr_refunded_hdemo_sk" => "5078",
          "cr_returning_addr_sk" => "7720298",
          "cr_return_amt_inc_tax" => "80.02",
          "cr_returning_cdemo_sk" => "598680",
          "cr_returning_hdemo_sk" => "2289",
          "cr_refunded_customer_sk" => "62244257",
          "cr_returning_customer_sk" => "39905396" }
      end

      it "correctly handles complex transformations for each record" do
        results = extractor.transform(sync, sync_record)
        expected_result = {
          "attributes" => { "properties" => { "fee" => "57.82" } }, "id" => "231891"
        }

        expect(results).to eq(expected_result)
      end
    end
  end
end
