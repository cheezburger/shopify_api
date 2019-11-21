module ShopifyAPI
  class FulfillmentOrder < Base
    def self.all(options = {})
      order_id = options.dig(:params, :order_id)
      raise ShopifyAPI::ValidationException, "'order_id' is required" if order_id.nil? || order_id == ''

      order = ::ShopifyAPI::Order.new(id: order_id)
      order.fulfillment_orders
    end

    def fulfillments(options = {})
      fo_fulfillments = get(:fulfillments, options)
      fo_fulfillments.map { |fof| FulfillmentOrderFulfillment.new(fof.as_json) }
    end

    def move(new_location_id:)
      body = { fulfillment_order: { new_location_id: new_location_id } }.to_json
      keyed_fos = load_keyed_attributes_from_response(post(:move, {}, body))
      if keyed_fos&.fetch('original_fulfillment_order', nil)&.attributes
        load(keyed_fos['original_fulfillment_order'].attributes, false, true)
      end
      keyed_fos
    end

    def cancel
      keyed_fos = load_keyed_attributes_from_response(post(:cancel, {}, only_id))
      if keyed_fos&.fetch('fulfillment_order', nil)&.attributes
        load(keyed_fos['fulfillment_order'].attributes, false, true)
      end
      keyed_fos
    end

    def close
      load_attributes_from_response(post(:close, {}, only_id))
    end

    def request_fulfillment(fulfillment_order_line_items:, message:)
      body = {
        fulfillment_request: {
          fulfillment_order_line_items: fulfillment_order_line_items,
          message: message
        }
      }
      keyed_fos = load_keyed_attributes_from_response(post(:fulfillment_request, {}, body.to_json))
      if keyed_fos&.fetch('original_fulfillment_order', nil)&.attributes
        load(keyed_fos['original_fulfillment_order'].attributes, false, true)
      end
      keyed_fos
    end

    def accept_fulfillment_request(params)
      load_attributes_from_response(post('fulfillment_request/accept', {}, params.to_json))
    end

    def reject_fulfillment_request(params)
      load_attributes_from_response(post('fulfillment_request/reject', {}, params.to_json))
    end

    def request_cancellation(message:)
      body = {
        cancellation_request: {
          message: message
        }
      }
      load_attributes_from_response(post(:cancellation_request, {}, body.to_json))
    end

    def accept_cancellation_request(params)
      load_attributes_from_response(post('cancellation_request/accept', {}, params.to_json))
    end

    def reject_cancellation_request(params)
      load_attributes_from_response(post('cancellation_request/reject', {}, params.to_json))
    end

    private

    def load_keyed_attributes_from_response(response)
      return load_attributes_from_response(response) if response.code != '200'

      keyed_fo_attributes = ActiveSupport::JSON.decode(response.body)
      keyed_fo_attributes.map do |key, fo_attributes|
        if fo_attributes.nil?
          [key, nil]
        else
          [key, FulfillmentOrder.new(fo_attributes)]
        end
      end.to_h
    end
  end
end
