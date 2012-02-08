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

def get_bytes(bstr)
	return if bstr.size % 8 != 0
	bytes = Array.new
	(bstr.size / 8).times do |k|
		index = k*8
		bytes[k] = bstr[index,8]
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
		skeys = get_bytes(kp)
		byte = (4 * (index / 12) + (index % 4)) % 8
		keys[index] = skeys[byte]
	end
	return keys
end

def generate_decryption_keys(key)
	keys = Array.new
	kp = key

	0.upto(191) do |index|
		skeys = get_bytes(kp)
		byte = (4 * (index / 12) + (index % 4)) % 8
		keys[index] = skeys[byte]
	   kp = right_shift(kp)
	end
	return keys
end	

key = "abcdef0123456789"
bkey = hex_to_binary(key)

keys = Array.new
kbytes = get_bytes(bkey)

keys = generate_encryption_keys(bkey)

0.upto(15) do |i|
	0.upto(11) do |j|	
		print "#{keys[i*16 + j].to_i(2).to_s(16)}\t"
	end
	print "\n"
end
