require "digest"
require "json"
require 'faraday'
require 'awesome_print'

class Blockchain

  attr_accessor :chain, :nodes, :current_node

  class << self
    def hash(blk)
      blk_str = JSON.dump (blk.sort).to_h
      Digest::SHA256.hexdigest blk_str
    end
  end

  def initialize
    @chain = []
    @current_transactions = []
    @nodes = Set.new
    @current_node = nil

    new_block(100, 1)
  end

  def new_block(proof, previous_hash=nil)
    # block = {
    #   'index': 1,
    #   'timestamp': 1506057125.900785,
    #   'transactions': [
    #       {
    #           'sender': "8527147fe1f5426f9dd545de4b27ee00",
    #           'recipient': "a77f5cdfa2934df3954a5c7c7da5df1f",
    #           'amount': 5,
    #       }
    #   ],
    #   'proof': 324984774000,
    #   'previous_hash': "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
    # }
    block = {
      index: @chain.count,
      timestamp: Time.now.to_i,
      transactions: @current_transactions,
      proof: proof,
      previous_hash: (previous_hash || Blockchain.hash(last_block))
    }
    @current_transactions = []
    @chain << block
    return block
  end

  def new_transaction(sender, recipient, amount)
    @current_transactions << {
      sender: sender,
      recipient: recipient,
      amount: amount
    }
    last_block[:index] + 1
  end

  def last_block
    @chain[-1]
  end

  def PoW(last_proof)
    # proof of work algorithm (PoW)
    proof = -1
    proof += 1 until valid_proof?(last_proof, proof)
    proof
  end


  def register_node(address)
    # TODO make sure this is a valid url path
    @nodes.add address
  end

  def resolve_conflicts
    new_chain = nil
    # Only looking for chains longer than this one
    max_length = @chain.count
    aval = @nodes.delete @current_node
    aval.each do |node|
      conn = Faraday.new(url: "http://#{node}/chain")

      res = conn.get do |conn_get|
        conn_get.options.open_timeout = 15
        conn_get.options.timeout = 15
      end
      if res.status == 200
        content = JSON.parse(res.body, symbolize_names: true)
        length = content[:data][:length]
        chain = content[:data][:chain]
        ap "node #{node} len #{length > max_length} valid_chain #{valid_chain?(chain)}"
        if length > max_length && valid_chain?(chain)
          max_length = length
          new_chain = chain
        end
      end
    end

    if new_chain
      puts "found new chain here"
      @chain = new_chain
      return true
    end
    return false
  end

  private
  def valid_proof?(last_proof, proof)
    Digest::SHA256.hexdigest("#{last_proof}#{proof}")[0..3] == "0000"
  end

  def valid_chain?(chain)
    last_block = chain[0]
    current_index = 1

    while current_index < chain.size
      block = chain[current_index]

      # Check that the hash of the block is correct
      if block[:previous_hash] != Blockchain.hash(last_block)
        return false
      end

      # Check that the Proof of Work is correct
      if !valid_proof?(last_block[:proof], block[:proof])
        return false
      end

      last_block = block
      current_index += 1
      return true
    end

  end
end
