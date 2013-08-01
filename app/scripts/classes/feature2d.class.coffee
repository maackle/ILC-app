
class Feature2D extends Feature
	
	constructor: (coords) ->
		super()
		@components = coords.map (p)->
			new Polygon(p)

		@L = new L.MultiPolygon coords[..],
			Settings.baseStyle()

	centroid: ->
		len = @components.length
		@components.map (poly)->
			poly.centroid()
		.reduce (a, b)->
			[a[0] + b[0], a[1] + b[1]]
		.map (x)->
			x / len

window.Feature2D = Feature2D