
class Polygon

	id: null
	L: null

	constructor: (coords) ->
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