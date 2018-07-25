# 区块链齐步走

想要理解区块链如何工作最好的方式就是制作一个啦。

[Learn Blockchains by Building One](https://hackernoon.com/learn-blockchains-by-building-one-117428612f46)
[加密货币与区块链（三）：什么是信任](https://zhuanlan.zhihu.com/p/36929944)
## Keywords
ruby, blockchain, consensus

## A

作为一个匪菜大军中的一员，不了解区块链是不能称为一个合格的匪菜的。空气币的火热，让更多的匪菜充满了渴望，似乎我们也需要了解一些在这个背后的基础。了解这个其实并不是很简单，因为更多的匪菜喜欢看到的是绿色的涨幅，而不是背后的技术，你可以在得（不）道上面找到很多奇怪的Talk，但是你的确得不到。    
我喜欢边做边学，看完下面的例子，我相信你能成为一颗不一样的匪菜。

## B

区块链（Blockchain），顾名思义就是由块组成的链，每一个块就是一些数据，然后通过一种手法把这个块连接起来，就是用一个哈希函数 H，把block B[i]的哈希值 H(B[i]) 包含在下一个 block B[i+1] 里。H 具有单向性，也就是知道 B 就很容易算出 H(B)，但是反过来如果只知道 H(B) 的值很难构造出一个满足条件的 B。当然啦，这个其实就是一个链表，POC。这样做的结果就意味着如果其中任何一块被修改了。而因为 H(B0) 是 B1 的一部分，所以导致 H(B1) 也要跟着变。如果有人要修改记录在这个链上的数据，就需要修改后面所有的块。这个就叫做Merkle List。如果你用过Gayhub，那么你应该也知道，Git存储的方式就是基于Merkle List。

## C

在你开始之前，我和你们说这篇教程使用的是Ruby语言写的。这里用了一些很简单的库来帮助我们可以做一个简单的Web Application，`cuba`, `faraday`。这里就不多做解释了。

## STEP 1
在开始前，你可以在这里看到源代码[传送门](https://github.com/lostpupil/build_a_blockchain)    

我们在这里创建一个Blockchain的Blueprint

```ruby
class Blockchain
end
```

Emmmm, that was a joke.

```ruby
class Blockchain

  class << self
    def hash blk
      
    end
  end
  def initialize
  end

  def new_block
  end

  def new_transacction
  end

  def last_block
  end
end
```

我们的Blockchain是用来对链初始化，然后添加一些常用的操作的，new_block, new_transaction, hash等。  

那么一个Block应该是什么样子的呢？   

```json
block = {
    'index': 1,
    'timestamp': 1506057125,
    'transactions': [
        {
            'sender': "8527147fe1f5426f9dd545de4b27ee00",
            'recipient': "a77f5cdfa2934df3954a5c7c7da5df1f",
            'amount': 5,
        }
    ],
    'proof': 324984774000,
    'previous_hash': "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
}
```

接下来我们需要创建新的块了，在我们的Blockchain初始化的时候，我们需要给他一个创世块，一个没有祖先的块，同时我们也需要给创世块增加一个 `proof` ，这是挖矿的结果，我稍后再说啦。  

我们现在需要了解什么是 PoW （Proof of Work），顾名思义就是新的区块是如何产生或者如何被挖出来的，它存在的目的就是发现能够解决一个问题的数字，这个数字需要具备两个属性，难找和易验证。  

我们举一个简单的例子

```python
from hashlib import sha256
x = 5
y = 0  # We don't know what y should be yet...
while sha256(f'{x*y}'.encode()).hexdigest()[-1] != "0":
    y += 1
print(f'The solution is y = {y}')
```

那么结果就是21，在比特币中，PoW的算法叫做Hashcash，和上面的例子是差不多的，矿工们算出结果之后是会被奖赏的，矿工会在一个交易中收到一个币。

PoW算法是很简单的，那么我们现在的题目就是：   
找到一个数字p，使得hash(pp')的结果包含是由4个0开头的。这里p代表之前的proof，p'是新的proof

```ruby
...

def PoW(last_proof)
  # proof of work algorithm (PoW)
  proof = 0
  while valid_proof?(last_proof, proof) == false
    proof += 1
  end
  proof
end
...

private
def valid_proof?(last_proof, proof)
  Digest::SHA256.hexdigest("#{last_proof}#{proof}")[0..3] == "0000"
end
```

如果你需要修改算法的难度，那么你只需要修改以0开头的个数就可以了。

## STEP 2

我们这里用 `cuba` 做一个很小的 web 服务，它主要包含了三个功能

* POST /transactions/new 生成一笔新的交易
* GET /mine 告诉服务器产生一个新的块
* GET /chain 把当前链返回


```ruby

node_identifier = SecureRandom.hex(20)
blockchain = Blockchain.new


Cuba.define do
  on get do
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

  end
end

```

接下来就可以跑一跑我们的简单的服务器啦

```
thin start -p 3000
```

你可以使用 Postman 或者 curl 来调用我们的服务。

## STEP 3

共识，这个很重要，在分布式系统中，你需要保证数据的一致性，所以你需要知道我们需要通过一种什么样的算法来保证我们始终指向一条链。    

* POST /nodes/register 我们把当前网络的节点都存到一个地方
* GET /nodes/resolve 这个地方用来解决冲突


```ruby
def valid_chain?(chain)
  last_block = chain[0]
  current_index = 1

  while current_index < chain.size
    block = chain[current_index]
    puts "count 1"
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
  end
  return true

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

# in server.rb

on 'nodes/resolve' do

  blockchain.current_node = "#{env["SERVER_NAME"]}:#{env["SERVER_PORT"]}"
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
```

valid_chain? 用来判断这个链是否正确的，可以看到 resolve_conflicts 里面主要用到的判断就是链长和是否是一条合格的链，如果更长并且合法，那么当前的链就替换为该链。不过这里值得注意的是，你需要把nodes中的自己的节点移除掉，这样其实是可以提高速度，并可以解决一个问题，单线程的机器中，你不能call自己。（会有一个OpenTimeOUt的错误，总是这里你把自己本身的节点去掉就可以了。）

到这里，你就可以用另一台机器或者使用不同的端口来模拟多个节点，我这边 Rakefile 里面默认是通过单机不同端口来模拟多个节点。

完整的代码请参考[传送门](https://github.com/lostpupil/build_a_blockchain)


## 你可以开始和小伙伴们玩耍这个蠢蠢的链了

希望这个东西能够给你一些启发。

当然啦，最后送上一句话。

> 如果你认为技术能解决安全问题，那么你既不懂安全也不懂技术。 :)

> 有很多关于区块链的文章都说「区块链解决的核心问题是信任问题」，但是我没有看到有人回答了关键的问题：到底什么是信任？什么是所谓「信任问题」，它存不存在？什么算是「解决了信任问题」？事实上如果在 Google 上搜一下这句话，会找到大量的复制粘贴和人云亦云。Brice Schneier 书里那句话改一改也是适用的，如果有人认为技术能解决信任问题，那么他恐怕既不懂信任也不懂技术。