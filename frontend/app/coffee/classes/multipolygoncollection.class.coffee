
class MultiPolygonCollection

	constructor: (@polygonClass, features) ->
		@items = {}
		@L = new L.FeatureGroup()

	addFeatures: (features) ->
		for feature in features
			if typeof(feature.geometry) == 'string'
				feature.geometry = $.parseJSON(feature.geometry)
			mp = new @polygonClass(feature)
			@items[feature.properties.gid] = mp
			@L.addLayer mp.L
		console.log "LL", @L


window.MultiPolygonCollection = MultiPolygonCollection