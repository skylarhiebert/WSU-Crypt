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
		rvals[i].insert(0, '0') until rvals[i].size == 16
	end

	return rvals
end

def F (r0, r1, round, ekeys)
	t0 = G(r0, ekeys[round*12], ekeys[round*12+1], 
			 ekeys[round*12+2], ekeys[round*12+3], round)
	t1 = G(r1, ekeys[round*12+4], ekeys[round*12+5],
			 ekeys[round*12+6], ekeys[round*12+7], round)
	f0 = (t0.to_i(2) + 2*t1.to_i(2) + (ekeys[round*12+8] + ekeys[round*12+9]).to_i(2)) % 2**16
	f0 = f0.to_s(2)
	f0.insert(0, '0') until f0.size == 16
	f1 = (2*t0.to_i(2) + t1.to_i(2) + (ekeys[round*12+10] + ekeys[round*12+11]).to_i(2)) % 2**16
	f1 = f1.to_s(2)
	f1.insert(0, '0') until f1.size == 16

	puts "Round #{round} : t0:#{binary_to_hex(t0)} \t t1:#{binary_to_hex(t1)} \t f0:#{binary_to_hex(f0)} \t f1:#{binary_to_hex(f1)}" if $debug

	return f0, f1
end

def G (r0, k0, k1, k2, k3, round)
	fTable = [0xa3,0xd7,0x09,0x83,0xf8,0x48,0xf6,0xf4,0xb3,0x21,0x15,0x78,0x99,0xb1,0xaf,0xf9,
		0xe7,0x2d,0x4d,0x8a,0xce,0x4c,0xca,0x2e,0x52,0x95,0xd9,0x1e,0x4e,0x38,0x44,0x28,
		0x0a,0xdf,0x02,0xa0,0x17,0xf1,0x60,0x68,0x12,0xb7,0x7a,0xc3,0xe9,0xfa,0x3d,0x53,
		0x96,0x84,0x6b,0xba,0xf2,0x63,0x9a,0x19,0x7c,0xae,0xe5,0xf5,0xf7,0x16,0x6a,0xa2,
		0x39,0xb6,0x7b,0x0f,0xc1,0x93,0x81,0x1b,0xee,0xb4,0x1a,0xea,0xd0,0x91,0x2f,0xb8,
		0x55,0xb9,0xda,0x85,0x3f,0x41,0xbf,0xe0,0x5a,0x58,0x80,0x5f,0x66,0x0b,0xd8,0x90,
		0x35,0xd5,0xc0,0xa7,0x33,0x06,0x65,0x69,0x45,0x00,0x94,0x56,0x6d,0x98,0x9b,0x76,
		0x97,0xfc,0xb2,0xc2,0xb0,0xfe,0xdb,0x20,0xe1,0xeb,0xd6,0xe4,0xdd,0x47,0x4a,0x1d,
		0x42,0xed,0x9e,0x6e,0x49,0x3c,0xcd,0x43,0x27,0xd2,0x07,0xd4,0xde,0xc7,0x67,0x18,
		0x89,0xcb,0x30,0x1f,0x8d,0xc6,0x8f,0xaa,0xc8,0x74,0xdc,0xc9,0x5d,0x5c,0x31,0xa4,
		0x70,0x88,0x61,0x2c,0x9f,0x0d,0x2b,0x87,0x50,0x82,0x54,0x64,0x26,0x7d,0x03,0x40,
		0x34,0x4b,0x1c,0x73,0xd1,0xc4,0xfd,0x3b,0xcc,0xfb,0x7f,0xab,0xe6,0x3e,0x5b,0xa5,
		0xad,0x04,0x23,0x9c,0x14,0x51,0x22,0xf0,0x29,0x79,0x71,0x7e,0xff,0x8c,0x0e,0xe2,
		0x0c,0xef,0xbc,0x72,0x75,0x6f,0x37,0xa1,0xec,0xd3,0x8e,0x62,0x8b,0x86,0x10,0xe8,
		0x08,0x77,0x11,0xbe,0x92,0x4f,0x24,0xc5,0x32,0x36,0x9d,0xcf,0xf3,0xa6,0xbb,0xac,
		0x5e,0x6c,0xa9,0x13,0x57,0x25,0xb5,0xe3,0xbd,0xa8,0x3a,0x01,0x05,0x59,0x2a,0x46]

	g = Array.new
	g[0] = r0[0, 8]
	g[1] = r0[8, 8]
	g[2] = (fTable[g[1].to_i(2) ^ k0.to_i(2)] ^ g[0].to_i(2)).to_s(2)
	g[2].insert(0, '0') until g[2].size == 8
	g[3] = (fTable[g[2].to_i(2) ^ k1.to_i(2)] ^ g[1].to_i(2)).to_s(2)
	g[3].insert(0, '0') until g[3].size == 8
	g[4] = (fTable[g[3].to_i(2) ^ k2.to_i(2)] ^ g[2].to_i(2)).to_s(2)
	g[4].insert(0, '0') until g[4].size == 8
	g[5] = (fTable[g[4].to_i(2) ^ k3.to_i(2)] ^ g[3].to_i(2)).to_s(2)
	g[5].insert(0, '0') until g[5].size == 8
	print "Round #{round} : " if $debug
	0.upto(g.size - 1) {|i| print "g#{i}:#{g[i].to_i(2).to_s(16)}\t" } if $debug
	print "\n" if $debug
	return g[4] + g[5]
end

def encrypt_block(blk, encrypt_key, key_schedule)
	rvals = whiten(blk, encrypt_key) # Whiten input

	# Start 16 rounds
	0.upto(15) do |round|
		fvals = F(rvals[0], rvals[1], round, key_schedule)

		# R2 xor F0, right-rotate by 1 bit -> R0
		xor = (rvals[2].to_i(2) ^ fvals[0].to_i(2)).to_s(2)
		xor.insert(0, '0') until xor.size == 16
		nr0 = right_shift(xor)

		# R3 rotate-left by 1 bit -> R3', R3' xor F1 -> R1
		nr1 = (left_shift(rvals[3]).to_i(2) ^ fvals[1].to_i(2)).to_s(2)
		nr1.insert(0, '0') until nr1.size == 16

		# Swap values around
		rvals[2] = rvals[0]
		rvals[3] = rvals[1]
		rvals[0] = nr0
		rvals[1] = nr1
	end

	y = rvals[2] + rvals[3] + rvals[0] + rvals[1] # Undo last swap

	return whiten(y, encrypt_key).join # Whiten output and join to 64-bit string
end

def decrypt_block(blk, decrypt_key, key_schedule)
	rvals = whiten(blk, decrypt_key) # Whiten input

	# Start 16 rounds
	0.upto(15) do |round|
		fvals = F(rvals[0], rvals[1], round, key_schedule)

		# R2 rotate-left by 1 bit -> R2', R2' xor F0 -> R0
		nr0 = (left_shift(rvals[2]).to_i(2) ^ fvals[0].to_i(2)).to_s(2)
		nr0.insert(0, '0') until nr0.size == 16

		# R3 xor F1, right-rotate by 1 bit -> R1
		xor = (rvals[3].to_i(2) ^ fvals[1].to_i(2)).to_s(2)
		xor.insert(0, '0') until xor.size == 16
		nr1 = right_shift(xor)

		# Swap values around
		rvals[2] = rvals[0]
		rvals[3] = rvals[1]
		rvals[0] = nr0
		rvals[1] = nr1
	end

	y = rvals[2] + rvals[3] + rvals[0] + rvals[1] # Undo last swap

	return whiten(y, decrypt_key).join # Whiten output and join to 64-bit string
end

def print_usage
	print "Usage: wsu-crypt [OPTION]... [-e|-d] FILE1 FILE2\n"
	print "Encrypt or Decrypt FILE1 with a key of FILE2 to standard output"
	print "\n\tDefault method is encryption"
	print "\n\n\t-e, -E, --encrypt\tEncrypt FILE1 with key FILE2"
	print "\n\t-d, -D, --decrypt\tDecrypt FILE1 with key FILE2"
	print "\n\t-h, -x\t\t\tOutput text to hexidecimal representations"
	print "\n\t-v, --verbose, --debug\tDisplay debug text to stdout"
	print "\n\t--help\t\t\tDisplay this help and exit"
	print "\n\t--version\t\tOutput version information end exit"
	print "\n\nExamples:\n\twsu-crypt -v -e plaintextfile keyfile"
	print "\n\twsu-crypt -d ciphertextfile keyfile"
	print "\n\nReport bugs to skylarhiebert@computer.org\n"
	exit
end

$debug = false
encrypt = true
pt_file = nil
key_file = nil
hex_output = false

# Parse Command Line Parameters
if ARGV.size < 2
	if ARGV[0] == "--version" or ARGV[0] == "-version"
		puts "wsu-crypt 1.0.0 (2012-8-2) [Skylar Hiebert]"
		exit
	end
	print_usage	# Too few arguments or --help defined
end

ARGV.size.times do |i|
	pt_file = ARGV[i] if i+1 == ARGV.size - 1
	key_file = ARGV[i] if i+1 == ARGV.size
	encrypt = true	if ARGV[i] == "-e"  or ARGV[i] == "-E" or ARGV[i] == "--encrypt"
	encrypt = false if ARGV[i] == "-d" or ARGV[i] == "-D" or ARGV[i] == "--decrypt"
	hex_output = true if encrypt and (ARGV[i] == "-h" or ARGV[i] == "-x")
	$debug = true if ARGV[i] == "-v" or ARGV[i] == "--verbose" or ARGV[i] == "--debug"
end
#puts "encrypt:#{encrypt} debug:#{$debug} pt_file:#{pt_file} key_file:#{key_file}"

plaintext = File.open(pt_file, 'rb') { |f| f.read.unpack('B*') }
keytext = File.open(key_file, 'rb') { |f| f.read }

bin_ptx = plaintext #plaintext.unpack('B*')
bin_key = keytext.unpack('B64')
encrypt_keys = generate_encryption_keys(bin_key[0])
decrypt_keys = generate_decryption_keys(bin_key[0])

#puts bin_ptx[0].size
#puts bin_ptx[0].size / 64

cipher = Array.new
cipher[0] = ""
0.upto(bin_ptx[0].size / 64 + 1) do |i|
	blk = bin_ptx[0][i*64, 64] unless bin_ptx[0][i*64].nil?
	unless blk.nil? 
		blk << '0' until blk.size == 64
		if encrypt
			cipher[0] << encrypt_block(blk, bin_key[0], encrypt_keys)
		else
			cipher[0] << decrypt_block(blk, bin_key[0], decrypt_keys)
		end
	end
	#puts blk
	#puts binary_to_hex(bin_ptx[0][i*64, 64]) unless bin_ptx[0][i*64].nil?
end

#print cipher.pack('B*')
puts hex_output == true ? cipher.pack('B*').unpack('H*')[0] : cipher.pack('B*')
#hex_output == true ? print binary_to_hex(cipher[0]) : print cipher.pack('B*')


# str.pack('B*')[0] converts string to binary string
# bstr.pack('B*') converts binary string to ascii
# hstr.pack('B*').unpack('H*')[0] converts binary to hex characters

key = "abcdef0123456789"
plaintext = "0123456789abcdef"
plaintext = plaintext.unpack('B*')[0]

bkey = hex_to_binary(key) # Use for debugging
#bkey = key.unpack('B64') # Use for generic code
bpt = hex_to_binary(plaintext)

ekeys = Array.new
dkeys = Array.new
kbytes = get_num_bits(bkey, 8)
ekeys = generate_encryption_keys(bkey)
dkeys = generate_decryption_keys(bkey)

=begin
0.upto(bin_ptx[0].size / 64 + 1) do |i|
	blk = plaintext[i*64, 64] unless plaintext[i*64].nil?
	unless blk.nil? 
		blk << '0' until blk.size == 64
		if encrypt
			cipher[0] << encrypt_block(blk, bkey, ekeys)
		else
			cipher[0] << decrypt_block(blk, bkey, dkeys)
		end
	end
	#puts blk
	#puts binary_to_hex(bin_ptx[0][i*64, 64]) unless bin_ptx[0][i*64].nil?
end
=end
#puts dkeys#.pack("C*")

# Print Key Table for debugging
#0.upto(15) do |i|
#	0.upto(11) do |j|
#		index = i*12 + j
#		print "#{ekeys[index].to_i(2).to_s(16)}:#{dkeys[index].to_i(2).to_s(16)}\t"
#	end
#	print "\n"
#end
eblk = encrypt_block(bpt, bkey, ekeys)
dblk = decrypt_block(eblk, bkey, dkeys)
#puts "Encrypt Block: #{binary_to_hex(eblk)}"
#puts "Decrypt Block: #{binary_to_hex(dblk)}"
