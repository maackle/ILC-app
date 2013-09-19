
class MultiPolygonCollection

	constructor: (type, features) ->
		@items = {}
		i = 0
		for feature in features

			if typeof(feature.geometry) == 'string'
				feature.geometry = $.parseJSON(feature.geometry)
			if type == 'industrial'
				mp = new IndustrialPolygon(feature)
			else if type == 'converted'
				mp = new ConvertedPolygon(feature)
			@items[feature.properties.GID] = mp

		ls = (mp.L for id, mp of @items)
		console.log ls
		@L = new L.FeatureGroup(ls)

window.MultiPolygonCollection = MultiPolygonCollection