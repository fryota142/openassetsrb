require 'rest-client'
module OpenAssets
  module Protocol

    class MarkerOutput
      include OpenAssets::Util
      extend OpenAssets::Util

      MAX_ASSET_QUANTITY = 2 ** 63 -1

      # A tag indicating thath this transaction is an Open Assets transaction.
      OAP_MARKER = "4f41"
      # The major revision number of the Open Assets Protocol.(1=0x0100)
      VERSION = "0100"

      attr_accessor :asset_quantities
      attr_accessor :metadata

      # @param [Array[Integer]] asset_quantities The asset quantity array
      # @param [String] metadata The metadata in the marker output.
      def initialize(asset_quantities, metadata = '')
        @asset_quantities = asset_quantities
        @metadata = metadata
      end

      # Serialize the marker output into a Open Assets Payload buffer.
      # @return [String] The serialized payload with hex format
      def to_hex
        payload = [OAP_MARKER, VERSION]
        asset_quantity_count = Bitcoin.pack_var_int(@asset_quantities.length).unpack("H*")
        payload << sort_count(asset_quantity_count[0])
        @asset_quantities.map{|q|payload << encode_leb128(q)}
        @metadata ||= ''
        metadata_length = Bitcoin.pack_var_int(@metadata.length).unpack("H*")
        payload << sort_count(metadata_length[0])
        payload << @metadata.bytes.map{|b| sprintf("%02x", b)}.join
        payload.join
      end

      # Serialize the marker output into a Open Assets Payload buffer.
      # @return [String] The serialized payload with binary format.
      def to_payload
        to_hex.htb
      end

      # Deserialize the marker output payload.
      # @param [String] payload The Open Assets Payload with binary format.
      # @return [OpenAssets::Protocol::MarkerOutput] The marker output object.
      def self.parse_from_payload(payload)
        p = payload.bth
        return nil unless valid?(p)
        p = p[8..-1] # exclude OAP_MARKER,VERSION
        asset_quantity, p = parse_asset_qty(p)
        list = to_bytes(p).map{|x|(x.to_i(16)>=128 ? x : x+"|")}.join.split('|')[0..(asset_quantity - 1)].join
        asset_quantities = decode_leb128(list)
        meta = to_bytes(p[list.size..-1])
        metadata =  meta.empty? ? '' : meta[1..-1].map{|x|x.to_i(16).chr}.join
        new(asset_quantities, metadata)
      end

      # Parses an output and returns the payload if the output matches the right pattern for a marker output,
      # @param [Bitcoin::Script] output_script: The output script to be parsed.
      # @return [String] The marker output payload with hex format if the output fits the pattern, nil otherwise.
      def self.parse_script(output_script)
        data = output_script.op_return_data
        return data.bth if data && valid?(data.bth)
      end

      # Creates an output script containing an OP_RETURN and a PUSHDATA from payload.
      # @return [Bitcoin::Script] the output script.
      def build_script
        Bitcoin::Script.from_string("OP_RETURN #{to_hex}")
      end
      alias_method :to_script, :build_script

      private
      def self.parse_asset_qty(payload)
        bytes = to_bytes(payload)
        case bytes[0]
          when "fd" then
            [(bytes[1]+bytes[2]).to_i(16), payload[6..-1]]
          when "fe" then
            [(bytes[1]+bytes[2]+bytes[3]+bytes[4]).to_i(16),payload[10..-1]]
          else
            [bytes[0].to_i(16),payload[2..-1]]
        end
      end

      def sort_count(count)
        bytes = to_bytes(count)
        case bytes[0]
          when "fd" then
            tmp         = count[2..3]
            count[2..3] = count[4..5]
            count[4..5] = tmp
            count
          when "fe" then
            tmp_1       = count[2..3]
            tmp_2       = count[4..5]
            count[2..3] = count[8..9]
            count[8..9] = tmp_1
            count[4..5] = count[6..7]
            count[6..7] = tmp_2
            count
          else
            count
        end
      end

      # validate marker output format
      # @param[String] data marker output data with hex format that start with 4f41.
      # @return [Boolean] if valid marker output return true, otherwise false.
      def self.valid?(data)
        return false if data.nil?
        # check open assets marker
        return false unless data.start_with?(OAP_MARKER + VERSION)
        # check asset quantity
        offset = [OAP_MARKER + VERSION].pack('H*').length
        count, offset = read_var_integer(data, offset)
        return false unless count
        # check metadata
        count.times do
          quantity, length = read_leb128(data, offset)
          return false if quantity.nil? || (length - offset) > 9
          offset = length
        end
        # check metadata
        length, offset = read_var_integer(data, offset)
        return false unless length
        return false if [data].pack('H*').bytes.length < length + offset
        true
      end

    end

  end
end
