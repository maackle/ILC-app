
class Feature2D extends Feature
	
	constructor: (coordinates) ->
		super()
		if Settings.switchLatLng
			coordinates = coordinates.map (polygons) ->
				polygons.map (points) ->
					if typeof points[0] == 'object'  # polygon is defined as multiple rings
						points = ([p[1], p[0]] for p in points)
					else
						points = [points[1], points[0]] 
		
		@components = coordinates.map (p)->
			new Polygon(p)

		@L = new L.MultiPolygon coordinates[..],
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