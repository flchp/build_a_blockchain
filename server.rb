require "cuba"
require "securerandom"
require 'awesome_print'
require "./blockchain.rb"

module Cuba::Sugar
  module As
    def as(http_code = 200, extra_headers = {}, &block)
      res.status = http_code
      res.headers.merge! extra_headers
      res.write yield if block
    end

    def as_json(http_code = 200, extra_headers = {}, &block)
      require 'json'
      extra_headers["Content-Type"] ||= "application/json"
      as(http_code, extra_headers) { yield.to_json if block }
    end
  end
end

node_identifier = SecureRandom.hex(20)
blockchain = Blockchain.new

Cuba.plugin Cuba::Sugar::As

Cuba.define do
  on get do

    on 'test' do
      ap req
      as_json {{ data: "test" }}
    end

    on 'mine' do
      last_block = blockchain.last_block
      last_proof = last_block[:proof]
      proof = blockchain.PoW(last_proof)

      blockchain.new_transaction("0", node_identifier.to_s, 1)

      previous_hash = Blockchain.hash(last_block)
      blk = blockchain.new_block(proof, previous_hash)

      data = {
        message: 'new block forged',
        index: blk[:index],
        transactions: blk[:transactions],
        proof: blk[:proof],
        previous_hash: blk[:previous_hash]
      }
      as_json {{ data: data }}
    end

    on 'chain' do
      as_json do
        {
          data: {
            chain: blockchain.chain,
            length: blockchain.chain.count
          }
        }
      end
    end

    on 'nodes/resolve' do
      blockchain.current_node = "#{req["SERVER_NAME"]}:#{req["SERVER_PORT"]}"
      resolved = blockchain.resolve_conflicts
      if resolved
        data = {
          message: "our chain was replaced",
          new_chain: blockchain.chain
        }
      else
        data = {
          message: "our chain was authorized",
          new_chain: blockchain.chain
        }
      end

      as_json {{ data: data }}
    end

  end

  on post do
    on 'transactions/new' do
      on param('sender'), param('recipient'), param('amount') do |sender, recipient, amount|
        index = blockchain.new_transaction(sender,recipient, amount.to_f)

        as_json {{ data: "transaction will be added to block #{index}"}}
      end

      on true do
        as_json 400 do
          { error: 'missing params'}
        end
      end
    end

    on 'nodes/register' do
      on param('nodes') do |nodes|
        nodes.split('|').each do |node|
          blockchain.register_node node
        end

        data = {
          message: "new nodes have been added",
          total_nodes: blockchain.nodes.to_a
        }

        as_json {{ data: data}}
      end
    end
  end
end
