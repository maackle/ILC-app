
class Polygon

	id: null
	L: null

	constructor: (coords) ->
		if typeof coords[0][0] == 'array'
			console.warn "cannot use polygon with holes, using exterior ring only."
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

	@makeList: (coord_list) ->
		coord_list.map (coords)->
			new Polygon(coords)

window.Polygon = Polygon