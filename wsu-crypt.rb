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
		skeys = get_num_bits(kp, 8)
		byte = (4 * (index / 12) + (index % 4)) % 8
		keys[index] = skeys[byte]
	end
	return keys
end

def generate_decryption_keys(key)
	keys = Array.new
	kp = key

	0.upto(191) do |index|
		skeys = get_num_bits(kp, 8)
		byte = (4 * (index / 12) + (index % 4)) % 8
		keys[index] = skeys[byte]
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
	p rvals
end

key = "abcdef0123456789"
plaintext = "0123456789abcdef"
bkey = hex_to_binary(key)
bpt = hex_to_binary(plaintext)

keys = Array.new
kbytes = get_num_bits(bkey, 8)

keys = generate_encryption_keys(bkey)

0.upto(15) do |i|
	0.upto(11) do |j|	
		print "#{keys[i*12 + j].to_i(2).to_s(16)}\t" 
	end
	print "\n"
end

whiten(bpt, bkey)
