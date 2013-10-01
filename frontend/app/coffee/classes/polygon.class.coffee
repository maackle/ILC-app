
class Polygon

	id: null
	L: null

	@_holesWarning: false

	constructor: (coords) ->
		if typeof coords[0][0] == 'object'
			if not Polygon._holesWarning
				console.warn "cannot use polygon with holes, using exterior ring only."
				Polygon._holesWarning = true
			coords = coords[0]
		@coords = coords[..]
		@L = new L.Polygon(coords)

	centroid: ->
		len = @coords.length
		sum = @coords.reduce (a, b)->
			[a[0] + b[0], a[1] + b[1]]
		ret = sum.map (x)->
			x / len
		ret


# class MultiPolygon

# 	id: null
# 	L: null

# 	components = []

# 	constructor: (coords) ->
# 		for c in coords
# 			if typeof c[0][0] == 'array'
# 				console.warn "cannot use polygon with holes, using exterior ring only."
# 				# TODO: FIX
# 			else
# 				@components.push = new Polygon(c)
# 		@coords = coords[..]
# 		@L = new L.MultiPolygon(coords)

# 	centroid: ->
# 		first = @coords[0] # HACK for now
# 		len = first.length
# 		sum = first.reduce (a, b)->
# 			[a[0] + b[0], a[1] + b[1]]
# 		ret = sum.map (x)->
# 			x / len
# 		ret


window.Polygon = Polygon
# window.MultiPolygon = MultiPolygon