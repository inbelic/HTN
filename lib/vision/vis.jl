#using Images
# Converts img to greyscale matrix representation of the image
#
# returns: mxn Float64 array
#function img_to_array(img_name)
#	img = load(img_name)
#	img = Gray.(img)
#	return convert(Array{Float64,2}, img)
#end

function load_array(file_name)
	value_arrays = []
	open(file_name) do file
		for ln in eachline(file)
			indices = [ c != "," for c in ln]
			values = split(ln, ",")
			push!(value_arrays, values)
		end
	end		
	
	size = (parse(Int,value_arrays[1][1]),parse(Int,value_arrays[1][2]))
	vals = parse.(Int,value_arrays[2][1:end-1])

	v = reshape(vals,size[1],size[2])

end

# Used to keep pixel intensity sums lower
switcheroo(x) = x = 1-x

man_norm(x) = sum(x.^2)^(1/2)

# Partitions image into num_cols * num_rows rectangles and returns the
# the partitions as t_images and the sum of the region's pixel intensity
# as sums
function get_regions(img,s,num_cols=2,num_rows=3)
	# initialize returned values
	sums = Float64[]	
	t_images = []
 
	for col in 1:num_cols
		for row in 1:num_rows
			# Reference the (col * row)th partition of img
			region = @view img[max(1,Int(round((row-1)*s[1]/num_rows))):Int(round(row*s[1]/num_rows)), 
												max(1,Int(round((col-1)*s[2]/num_cols))):Int(round(col*s[2]/num_cols))]
			 
			push!(t_images, region)
			
			push!(sums, man_norm(region)) 
		end
	end
	return sums, t_images
end

# Take the sums matrix and output a matrix that represents the
# braille representation
function get_output_vector(sums,tol_div=4, zero_tol=5)
	largest = maximum(sums)
	tolerance = largest/tol_div	
	vect = [ abs(largest - sum) < tolerance for sum in sums] 
	if largest < zero_tol
		vect = zeros(6)
	end
	return Int.(reshape(vect,3,2))
end 

# Given an image of a single char we return the regions of the
# image, the sums of those regions and the output vector
#
function process_char(img)
	s = size(img)
	sums, t_images = get_regions(img,s)
	output_vector = get_output_vector(sums)
	return output_vector
end

# Preliminary version of processing the image to feed the
# single characters to the process_char function
#
function process_chars(img,s,num_chars)
	chars = [ @view img[:,max(1,Int(round((col-1)*s[2]/num_chars))):Int(round(col*s[2]/num_chars))]
						for col in 1:num_chars ]
	
	outputs = [ process_char(char) for char in chars ]
	return outputs
end

function row_to_num_chars(l_row)
	last_col = 0	
	distance = 0
	distances = Int64[]
	dot_size = 0
	dot_sizes = Int64[]	
	
	for col in l_row 
		distance += 1
		dot_size += 1
		if col > 0 && last_col == 0
			push!(distances, distance)
			dot_size = 0
		
		elseif col == 0 && last_col > 0
			push!(dot_sizes, dot_size)
			distance = 0
		end
		
		last_col = col
	end
	
	return distances, maximum(dot_sizes)
end

function optimize_x(t_sum, dot_size, inner_dist, outer_dist)
	x = 2
	y = 1
	z = 0

	while dot_size*x + y*inner_dist + z*outer_dist < t_sum
		x += 2
		y = x/2
		z = x/2 - 1
	end
	
	return (x, y, z)
end

function get_distances(img,s)
	l_row = img[1,:]
	l_row_sum = 0
	for row_num in 1:s[1]
		row = @view img[row_num, :]
		row_sum = sum(row)
		if row_sum >= l_row_sum
			l_row = row
			l_row_sum = row_sum
		end
	end	
	distances, dot_size = row_to_num_chars(l_row)
	return distances, dot_size
end

function determine_chars(distances, dot_size)
	
	t_sum = sum([distance + dot_size for distance in distances[2:end]])
	
	inner_dist = minimum(distances)
	outer_dist = maximum(distances)
	opt_x = optimize_x(t_sum, dot_size, inner_dist, outer_dist)

	return t_sum, opt_x
end

function get_min_space(distances, tolerance=3)
	s_dists = sort(distances, rev=true)
	min_space = s_dists[1]
	for col in 2:size(s_dists)[1]
		gap = abs(min_space - s_dists[col])
		if gap > min_space/tolerance
			return min_space
		end
		min_space = s_dists[col]
	end	
	return Inf
end

function get_words(img, distances, dot_size, indices)
	cur_region_strt = 1
	cur_region_end = cur_region_strt
	
	dot_ticker = 1

	words = []
	for col in 2:size(distances)[1] 
		if dot_ticker > 0
			cur_region_end += dot_size
		end
		dot_ticker = mod(dot_ticker + 1,3)
		cur_region_end += distances[col]	
		if indices[col]
			word = @view img[:,cur_region_strt:cur_region_end]	
			push!(words,word)
			cur_region_strt = cur_region_end 
		end	
	end
	word = @view img[:,cur_region_strt:end]
	push!(words,word)
	return words
end

function vert_trim(word)
	while true
		if sum(word[1,:]) > 0
			break
		end
		word = @view word[2:end,:]
	end
	while true
		if sum(word[end,:]) > 0
			break
		end
		word = @view word[1:end-1,:]
	end
	return word
end

function horiz_trim(word)
	while true
		if sum(word[:,1]) > 0
			break
		end
		word = @view word[:,2:end]
	end
	while true
		if sum(word[:,end]) > 0
			break
		end
		word = @view word[:,1:end-1]
	end
	
	return word
end

function add_padding(word)
	s = size(word)
	word = [ zeros(5,s[2]); word; zeros(5,s[2])]
	
	word = [ zeros(s[1]+10,10) word zeros(s[1]+10,10) ]
	return word
end

function trim_word(word)
	word = vert_trim(word)
	word = horiz_trim(word)
	word = add_padding(word)	
	return word
end

function image_to_braille(file_name)
	img = load_array(file_name)
	img = map(switcheroo,img)
	
	s = size(img)
	distances, dot_size = get_distances(img,s)
	braille_chars = []
	
	min_space = get_min_space(distances)
	indices = [ dist >= min_space for dist in distances]

	words = get_words(img, distances, dot_size, indices)
	for word in words
		word = trim_word(word)
		distances, dot_size = get_distances(word,size(word))
		t_sum, opt_x = determine_chars(distances,dot_size)
		num_chars = opt_x[1]/2	
		outputs = process_chars(word, size(word), num_chars)
		if sum(sum(outputs)) > 0
			push!(braille_chars, outputs, [[0 0; 0 0; 0 0]])
		end	
	end
	return braille_chars
end

