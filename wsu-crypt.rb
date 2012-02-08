#!/usr/bin/env ruby

def hex_to_binary(str)
	bin = ""
	str.chars do |c|
		c_str = c.to_i(16).to_s(2)
		c_str.insert(0, "0") until c_str.size == 4
		bin << c_str
	end
	return bin
end

def binary_to_hex(str)
	str.to_i(2).to_s(16)
end

def get_num_bits(bstr, bits)
	return if bstr.size % bits != 0
	bytes = Array.new
	(bstr.size / bits).times do |k|
		index = k*bits
		bytes[k] = bstr[index,bits]
	end
	return bytes
end

def left_shift(bstr)
	bstr.slice(1, bstr.size) + bstr.slice(0, 1)
end

def right_shift(bstr)
	bstr.slice(bstr.size - 1, 1) + bstr.slice(0, bstr.size - 1)
end

def generate_encryption_keys(key)
	keys = Array.new
	kp = key
	
	0.upto(191) do |index|
		kp = left_shift(kp) # left rotate
		skeys = get_num_bits(kp, 8) # .reverse for other subkey schedule
		byte = (4 * (index / 12) + (index % 4)) % 8
		keys[index] = skeys[byte]
	end
	return keys
end

def generate_decryption_keys(key)
	keys = Array.new
	kp = key

	0.upto(191) do |index|
		skeys = get_num_bits(kp, 8).reverse # Opposite of encryption
		byte = (4 * (index / 12) + (index % 4)) % 8
		# Slot is to reverse 12 keys (11 downto 0, then 23 downto 12)
		slot = (12 * (index/12 + 1) - 1) - index % 12
		# Reverse Key Ordering, 
		keys[slot] = skeys[byte] 
	   kp = right_shift(kp)
	end
	return keys
end	

def whiten (text, key)
	words = get_num_bits(text, 16)
	wkeys = get_num_bits(key, 16)
	rvals = Array.new
	0.upto(3) do |i|
		rvals[i] = (words[i].to_i(2) ^ wkeys[i].to_i(2)).to_s(2)
	end
	return rvals
end

def F (r0, r1, round)
		
end

def G (r0, round)
	g = Array.new
	g[1] = r0[0, 8]
	g[2] = r0[8, 8]
	p g
end

# str.pack('B*')[0] converts string to binary string
# bstr.pack('B*') converts binary string to ascii
# hstr.pack('B*').unpack('H*')[0] converts binary to hex characters

key = "abcdef0123456789"
plaintext = "0123456789abcdef"
bkey = hex_to_binary(key) # Use for debugging
#bkey = key.unpack('B64') # Use for generic code
bpt = hex_to_binary(plaintext)

ekeys = Array.new
dkeys = Array.new
kbytes = get_num_bits(bkey, 8)
ekeys = generate_encryption_keys(bkey)
dkeys = generate_decryption_keys(bkey)

#puts dkeys#.pack("C*")

# Print Key Table for debugging
0.upto(15) do |i|
	0.upto(11) do |j|
		index = i*12 + j
		print "#{ekeys[index].to_i(2).to_s(16)}:#{dkeys[index].to_i(2).to_s(16)}\t"
	end
	print "\n"
end

rvals = whiten(bpt, bkey)
p binary_to_hex(rvals.join)
round = 0
G(rvals[0], round)
