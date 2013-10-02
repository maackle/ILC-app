
class MultiPolygonCollection

	constructor: (@polygonClass, features) ->
		@items = {}
		@sorted = []
		@L = new L.FeatureGroup()

	addFeatures: (features) ->
		for feature in features
			if typeof(feature.geometry) == 'string'
				feature.geometry = $.parseJSON(feature.geometry)
			mp = new @polygonClass(feature)
			@items[feature.properties.gid] = mp
			@sorted.push mp
			@L.addLayer mp.L
		if @polygonClass == IndustrialPolygon
			@sorted.sort (a,b) ->
				b.size_metric - a.size_metric


window.MultiPolygonCollection = MultiPolygonCollection