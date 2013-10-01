
class ConvertedPolygon extends Feature2D

	constructor: (data) ->
		super(data.geometry.coordinates)

		@convertedTo = switch data.properties.twlsm.trim().toUpperCase()
			when 'R' then ''

		@L.setStyle
			# dashArray: "3 6"
			fillOpacity: 0
			weight: 3
			color: Settings.convertedColors[data.converted_to] or Settings.convertedColors['NON']
			fillColor: null #Settings.convertedColors[data.converted_to] or Settings.convertedColors['NON']
			clickable: false

window.ConvertedPolygon = ConvertedPolygon