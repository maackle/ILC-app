
class ConvertedPolygon extends Feature2D

	constructor: (data) ->
		super(data.geometry.coordinates)

		dataset = ILC.dataset

		convProp = if dataset == 'cook' then 'twlsm' else 'cnvrtd_t'  #TODO:CONFIG
		@convertedTo = data.properties[convProp].trim().toUpperCase()

		color = Settings.convertedColors[dataset][@convertedTo]
		if not color?
			console.log @convertedTo

		@L.setStyle
			# dashArray: "3 6"
			fillOpacity: 0
			weight: 3
			color: color or Settings.convertedColors[dataset]['NON']
			clickable: false

window.ConvertedPolygon = ConvertedPolygon