#!/usr/bin/env ruby

key = "abcdef0123456789"

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
	return if bstr.length % 8 != 0
	bytes = Array.new
	for(k = 0; k < bstr.length / 8; k += 1)
		index = k*8
		puts index
		bytes[k] = bstr[index..index+8]
	end
	return bytes
end

bkey = hex_to_binary(key)

p bkey

keys = Array.new
kbytes = get_bytes(bkey)

p kbytes

for (i = 0; i < 16; i += 1) 
	for (j = 0; j < 12; j += 1)

	end
end
