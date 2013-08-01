
class MultiPolygonCollection

	constructor: (type, multipolygons) ->
		@items = {}
		i = 0

		for data in multipolygons
			if type == 'industrial'
				mp = new IndustrialPolygon(data)
			else if type == 'converted'
				mp = new ConvertedPolygon(data)
			@items[data.gid] = mp

		ls = (mp.L for id, mp of @items)
		@L = new L.FeatureGroup(ls)

window.MultiPolygonCollection = MultiPolygonCollection