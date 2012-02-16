#!/usr/bin/env ruby

# http://en.wikipedia.org/wiki/Extended_Euclidean_algorithm
def extended_gcd(a, b) 
	return -1, 0 if b == 0 and a < 0 
	return 1, 0 if b == 0 and a > 0
	
	q = a / b
	r = a % b
	st = extended_gcd(b, r)
	v = st[0] - q * st[1]
	
	return st[1], v
end

# http://en.wikipedia.org/wiki/Extended_Euclidean_algorithm
def get_multiplicative_inverse
	# remainder[1] := f(x)
	# remainder[2] := a(x)
	# auxiliary[1] := 0
	# auxiliary[2] := 1
	# i := 2
	# while remainder[i] > 1
	#    i := i + 1
	#    remainder[i] := remainder(remainder[i-2] / remainder[i-1])
	#    quotient[i] := quotient(remainder[i-1] / remainder[i-1])
	#    auxiliary[i] := -quotient[i] * auxiliary[i-1] + auxiliary[i-2]
	# inverse := auxiliary[i]
end	

p extended_gcd(120, 23)
