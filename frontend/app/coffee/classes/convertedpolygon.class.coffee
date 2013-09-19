
class ConvertedPolygon extends Feature2D

	constructor: (data) ->
		super(data.geometry.coordinates)

		@L.setStyle
			# dashArray: "3 6"
			fillOpacity: 0
			weight: 3
			color: window.convertedColors[data.converted_to] or window.convertedColors['NON']
			fillColor: null #window.convertedColors[data.converted_to] or window.convertedColors['NON']
			clickable: false

window.ConvertedPolygon = ConvertedPolygon