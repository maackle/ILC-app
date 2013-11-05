
window.ILC = 

	map: null
	industrial: null
	naics_trends: null
	visibleIndustrialFeatures: []
	_pxScale: null
	layers: {}
	vectorLayers: {}
	currentRasterLayer: null
	currentRasterKey: null
	currentNAICS3: null

	colormap: ->
		Colormap.loaded[Colormap.currentIndex]

	pxScale: ->
		map = ILC.map
		pb = map.getPixelBounds()
		b = map.getBounds()
		ne = b.getNorthEast()
		sw = b.getSouthWest()
		lat = ne.lat - sw.lat
		lng = ne.lng - sw.lng
		dx = pb.max.x - pb.min.x
		dy = pb.max.y - pb.min.y
		if lat > lng
			@_pxScale = dy / lat
		else
			@_pxScale = dx / lng
		@_pxScale

	datapath: (dataset) ->
		dataset ?= ''
		if dataset[-1] == '/'
			dataset = dataset[0:-2]
		if 'localhost' in window.location
			"/data/#{dataset}"
		else
			"data/#{ dataset }"

	initialize: (opts) ->
		{dataset, limit} = opts
		@dataset = dataset
		@initLeaflet('leaflet-map')
		ILC.addPolygons(dataset, limit)
		ILC.loadData(dataset)
		@graphs.naics_trends.initialize()
		@graphs.histogram.initialize()
		@graphs.demography.race.initialize()
		@graphs.demography.occupation.initialize()
		# @pxScale()
		if dataset != 'meck'
			$('.meck-only').remove()  # TODO: read settings
		if dataset != 'cook'
			$('.cook-only').remove()  # TODO: read settings
		

	## Returns the initialized map object
	initLeaflet: (id)->
		@map = L.map id,
			zoomControl: false
		
		L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/map//{z}/{x}/{y}.png', {
		    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>.  Tiles Courtesy of <a href="http://www.mapquest.com/" target="_blank">MapQuest</a> <img src="http://developer.mapquest.com/content/osm/mq_logo.png">'
		    minZoom: Settings.baseMinZoom
		    subdomains: '1234'
		    opacity: 0.5
		})
		# .bindPopup ->
		.addTo(@map)

		@map
		.on 'click', (e)=>
			IndustrialPolygon.clearActive(e.originalEvent)
			ILC.graphs.hideNonHistogram()
			ILC.graphs.histogram.updateActive()
			# $('.toggler').popover('hide')
		.on 'moveend', (e) =>
			if @graphs.histogram.layout?
				@graphs.histogram.update()
			ILC.updateVisibleFeatures()
		.on 'zoomend', (e) =>
			zoom = e.target._zoom
			ILC.resizeDivIcons(zoom)

			ILC.updateVisibleFeatures()
			if ILC.currentRasterLayer?
				if @map.getZoom() > Settings.rasterMaxZoom
					ILC.graphs.show()
				else
					ILC.graphs.hide()
		.on 'overlayadd', (e) ->
			console.log 'add', e
		.on 'overlayremove', (e) ->
			console.log 'remove', e
		.on 'baselayerchange', (e) ->
			console.log 'change', e

		@map

	resizeDivIcons: (zoom) ->
		size = Math.max(2.5, (zoom - 11)*2 + 0)
		$('.brownfield-divicon').css
			width: size
			height: size
			'margin-left': -size/2
			'margin-top': -size/2

	resetLegend: ->
		$('#legend .colormap').html('').append(@colormap().legendHTML())

	updateVisibleFeatures: ->
		previousNum = @visibleIndustrialFeatures.length
		group = ILC.industrial
		group.L.clearLayers()
		pxScale = @pxScale()
		mapBounds = ILC.map.getBounds()
		num = 0
		@visibleIndustrialFeatures = []
		for f in group.sorted when f.risk()? and (@currentNAICS3 == null or f.naics3 == @currentNAICS3) and f.L.getBounds().intersects(mapBounds) 
			if num < Settings.maxVisibleFeatures #and f.size_metric * pxScale > Settings.minSizeMetric
				f.pxSizeEstimate = f.size_metric * pxScale
				group.L.addLayer(f.L)
				@visibleIndustrialFeatures.push f
			num += 1
		numVisible = @visibleIndustrialFeatures.length
		if numVisible < num
			$('#feature-limit').html("showing #{numVisible} of #{num} features").fadeIn()
		else
			$('#feature-limit').html("showing #{numVisible} of #{num} features").fadeOut()
		console.log 'num features visible:', @visibleIndustrialFeatures.length, num
		
		# TODO: OPTIMIZE: only update features that were added
		@updateFeatures()

		# deactivate active feature if it's no longer visible
		# if IndustrialPolygon.activeFeature? and @visibleIndustrialFeatures.length <= previousNum
		if IndustrialPolygon.activeFeature? and not (IndustrialPolygon.activeFeature.gid in @visibleIndustrialFeatures.map (f) -> if f? then f.gid else null)
			IndustrialPolygon.clearActive()
			ILC.graphs.hideNonHistogram()


	updateFeatures: ->
		features = @visibleIndustrialFeatures
		colormap = @colormap()
		for id, f of features when not (IndustrialPolygon.activeFeature? and IndustrialPolygon.activeFeature.gid == f.gid)
			f.updateColor(colormap)

	getRiskRange: ->
		# features = @visibleIndustrialFeatures
		features = @industrial.items
		risks = (f.risk() for id, f of features)
		extent = [Math.min.apply(null, risks), Math.max.apply(null, risks)]
		extent

	_updateLegendVisibility: ->
		other = $(".other-legends")
		if other.find('.legend-container.active').length == 0
			other.fadeOut()
		else
			other.fadeIn()

	addVector: (key) ->
		console.log 'addVector', key, ILC.vectorLayers
		ILC.map.addLayer(ILC.vectorLayers[key])
		$('#legend').find(".legend-container.#{key}").addClass('active').fadeIn()
		@_updateLegendVisibility()
		if key == 'brownfields'
			ILC.resizeDivIcons(ILC.map.getZoom())

	removeVector: (key) ->
		ILC.map.removeLayer(ILC.vectorLayers[key])
		$('#legend').find(".legend-container.#{key}").removeClass('active').fadeOut()
		@_updateLegendVisibility()


	setRaster: (id, fmt, opts) ->
		fmt = fmt || "png"
		if id == @currentRasterKey then return

		if @currentRasterLayer?
			@map.removeLayer(@currentRasterLayer)
			$('#legend .raster-legends img').hide()
		
		if id? && id != ''
			urlTemplate = @datapath("#{@dataset}/tiles/#{ id }/{z}/{x}/{y}.#{ fmt }")
			@currentRasterLayer = L.tileLayer(urlTemplate, opts).addTo(@map)
			ILC.graphs.hide()
			$("#legend .raster-legends img[data-id=#{id}]").fadeIn()
		else
			@currentRasterLayer = null
			ILC.graphs.show()
		@currentRasterKey = id


	addPolygons: (dataset, limit) ->

		calculateStuff = (features) =>
			riskRange = @getRiskRange()
			Colormap.updatePreviews(Settings.initialColorBins)
			Colormap.setCurrent(0)
			ILC.resetLegend()
			@updateFeatures()

		loadIndustrialChunk = (i) =>
			url_industrial = @datapath(dataset) + "/json/industrial-#{i}.geojson"

			res_i = HTTP.call 'GET', url_industrial
			res_i.done (data) =>
				if Settings.requireDemography
					feats = (f for f in data.features when f.properties.demography.race.multi?)
				else
					feats = data.features
				feats = data.features
				@industrial.addFeatures(feats)
				console.debug 'feats', feats
				if i == 0
					bounds = @industrial.L.getBounds()
					map.fitBounds(bounds) 
				ILC.vectorLayers['industrial-parcels'] = @industrial.L
				@updateVisibleFeatures()
				calculateStuff(@visibleIndustrialFeatures)
			res_i


		loadConvertedChunk = (i) =>
			url_converted = @datapath(dataset) + "/json/converted-#{i}.geojson"

			res_c = HTTP.call 'GET', url_converted
			res_c.success (data) =>
				@converted.addFeatures(data.features)
				ILC.vectorLayers['converted-parcels'] = @converted.L
			res_c


		map = @map
		limit_str = 
			if limit?
				'?limit='+limit
			else
				''

		@industrial = new MultiPolygonCollection(IndustrialPolygon)
		@converted = new MultiPolygonCollection(ConvertedPolygon)
		@industrial.L.addTo(map)
		# @converted.L.addTo(@map)

		Colormap.updatePreviews(Settings.initialColorBins)
		Colormap.setCurrent(0)

		# TODO: save these layers but only add them to map when the mouse has not moved for 1 second
		chunks = 0
		async.whilst (() -> not Settings.DEBUG_MODE or chunks < 1),
			(callback) -> 
				res = loadIndustrialChunk(chunks)
				res.done () -> setTimeout (-> callback()), 1000
				res.fail (err) -> callback(err)
				chunks += 1
			,
			(err) ->
				console.log 'done reading industrial polygons'
		
		chunks = 0
		async.whilst (() -> not Settings.DEBUG_MODE or chunks < 1),
			(callback) -> 
				res = loadConvertedChunk(chunks)
				res.done () -> setTimeout (-> callback()), 1000
				res.fail (err) -> callback(err)
				chunks += 1
			,
			(err) ->
				console.log 'done reading converted polygons'
		




	loadData: (dataset)->
		# res = HTTP.blocking 'GET', '/api/charlotte/industrial/naics-trends'
		res = HTTP.blocking 'GET',  @datapath(dataset) + '/naics-trends.json'
		res.success (data) =>
			@naics_trends = data.naics_trends
			console.log 'NAAAAICS', @naics_trends

		res = HTTP.blocking 'GET', @datapath() + '/naics-list.json'
		res.success (data) =>
			@naics_list = data.naics_list

		if not Settings.skipBrownfields
			res = HTTP.blocking 'GET',  @datapath(dataset) + '/brownfields.geojson'
			res.success (data) =>
				@layers.brownfields = L.geoJson data,
					pointToLayer: (feature, latlng) ->
						new L.Marker latlng,
							clickable: false
							icon: L.divIcon
								className: 'brownfield-divicon'
							# icon: L.icon
							#     iconUrl: 'static/img/brownfield-icon.png',
							#     iconSize: [24, 24],
							#     iconAnchor: [12, 12],
				ILC.vectorLayers['brownfields'] = @layers.brownfields

		list = ([code, title] for code, title of @naics_list when title != '???' )
		list = list.sort (a, b) -> 
			 if a[1] < b[1] then -1
			 else 1
		groups = {}
		for line in list
			code = line[0]
			name = line[1]
			code3 = code.substr(0, 3)
			if not groups[code3]
				groups[code3] = []
			groups[code3].push code
		for code3, codes of groups
			name = @naics_list[code3]
			$optgroup = $("""<optgroup label="#{ name }"></optgroup>""")
			for code in codes
				name = @naics_list[code]
				$opt =
					if code == code3
						"""<option value="#{ code }" class="primary">#{ name }</option>"""
					else
						"""<option value="#{ code }">#{ name }</option>"""
				$optgroup.append("""<option value="#{ code }">#{ name }</option>""")
			$('.industry-select').append($optgroup)
		$('.industry-select').chosen
			allow_single_deselect: true



	graphs:

		$container: -> $('#graphs')

		show: -> 
			this.$container().fadeIn()

		hide: -> this.$container().fadeOut()

		hideNonHistogram: ->

			ILC.graphs.demography.race.hide()
			ILC.graphs.demography.occupation.hide()
			ILC.graphs.naics_trends.hide()
			$('#legends-and-colormaps').fadeIn()

		naics_trends:

			$container: -> $('#naics-trends-graph')
			lines:
				county: null
				state: null
				nation: null
			svg: null

			xAxis: ->
				d3.svg.axis()
					.scale(@x)
					.orient('bottom')
					.tickValues([1990, 2000, 2010])
					.tickFormat(d3.format("d"))

			yAxis: -> 
				d3.svg.axis()
					.scale(@y)
					.orient('left')
					.tickValues([1])
					.ticks(4)
					.tickSubdivide(0.25)

			hide: ->
				@$container().fadeOut()

			show: ->
				@$container().fadeIn()

			initialize: ->
				margin=
					top: 5
					left: 25
					bottom: 25
					right: 25
				width = Settings.graphWidth
				height = Settings.lineGraphHeight

				@x = d3.scale.linear()
					.domain([1990, 2010])
					.range([0, width - margin.left - margin.right])
				@y = d3.scale.linear()
					.domain([0, 3])
					.range [height - margin.top - margin.bottom, 0]

				@lines.county = d3.svg.line()
					.x( (d) => @x(d.year) )
					.y( (d) => @y(d.value) )
				@lines.state = d3.svg.line()
					.x( (d) => @x(d.year) )
					.y( (d) => @y(d.value) )
				@lines.nation = d3.svg.line()
					.x( (d) => @x(d.year) )
					.y( (d) => @y(d.value) )

				@svg = d3.select('#naics-trends-graph')
					.append('svg:svg')
						.attr('width', width)
						.attr('height', height)
					.append('g')
						.attr 'transform', "translate(#{ margin.left }, #{ margin.top })"

				lineStyle = (name) -> 
					opts = 
					fill: 'none'
					class: name
					stroke: (
						if name=='county' then makeColorString(Settings.graphs.trends.colors[0])
						else if name=='state' then makeColorString(Settings.graphs.trends.colors[1])
						else makeColorString(Settings.graphs.trends.colors[2])
					)
					'stroke-width': (
						if name=='county' then 2
						else 1
					)

				@svg.append('path').attr(lineStyle('county'))
				@svg.append('path').attr(lineStyle('state'))
				@svg.append('path').attr(lineStyle('nation'))

				@svg.append("g")
					.attr("class", "x axis")
					.attr("transform", "translate(0," + (height-margin.bottom-margin.top) + ")")
					.call(@xAxis())

				@svg.append("g")
					.attr("class", "y axis")
					.call(@yAxis())
				# .append("text")
				# 	.attr("transform", "rotate(-90)")
				# 	.attr("y", 6)
				# 	.attr("dy", ".71em")
				# 	.style("text-anchor", "end")
				# 	.text("Price ($)")


			setNAICS: (naics_code) ->

				if naics_code? && naics_code > 0
					@show()

					naicsTitle = ILC.naics_list[naics_code]

					@$container().find('.info .naics-title').text("#{naics_code} - #{naicsTitle}")
					@$container().find('.naics').text("#{naics_code}")
					@$container().find('.info .naics-filter-select').click (e) ->
						$('.industry-select').val(naics_code)
						$('.industry-select').trigger("liszt:updated");
						ILC.currentNAICS3 = naics_code.substr(0, 3)
						ILC.updateVisibleFeatures()
						false

					countywide = ILC.naics_trends.countywide[naics_code] or []
					nationwide = ILC.naics_trends.nationwide[naics_code] or []
					# statewide is different -- it's a total across all industries
					statewide = ILC.naics_trends.statewide["31-33"] or []

					data = {}

					# ASSUMPTIONS:
					# - data starts at 1990
					# - county data will always be the limiting factor, e.g. will always start the same or later than state or national
					# 
					# State and national data will be full from 1990 - present
					# However county data may be sparse, with no values before baseYear
					# and other values cut out
					
					if countywide.emp_growth?
						data.county = countywide.emp_growth.filter (d) -> d.value?
						countywide_base_year = data.county.map((d) -> d.year).reduce((a,b) -> if a < b then a else b)
						console.assert(countywide_base_year == parseInt(countywide.base_year))
					else
						console.warn 'no county data', countywide
						data.county = []
						countywide_base_year = 1990

					statewide_base_year = if statewide? then parseInt(statewide.base_year) else null
					console.assert(statewide_base_year == 1990)
					baseYear = Math.max(countywide_base_year, statewide_base_year)
					baseX = @x(baseYear)

					meta = 
						county:
							baseIndex: 0
						state:
							baseIndex: baseYear - 1990
						nation:
							baseIndex: baseYear - 1990

					data.state = statewide.emp_growth
					data.nation = nationwide.emp_growth

					min = 999
					max = -999
					for k, datum of data when datum?
						for d in datum
							# console.log datum, d, baseIndex
							d.value /= datum[meta[k].baseIndex].value
							if d.value < min then min = d.value
							if d.value > max then max = d.value

					extent = [0, max]
					@y.domain(extent)

					@svg.select('.y.axis').transition().duration(777)
						.attr('transform', "translate(#{ baseX }, 0)")
						.call(@yAxis())

					for which, datum of data
						@svg.select("path.#{ which }")
							.datum(datum)
							.transition().duration(777)
							.attr('d', @lines[which])
					@show()
				else
					@hide()
					return


		demography:

			race: new StackedBarChart 
				width: Settings.barGraphWidth
				height: 120
				name: 'race'
				legendData:
					white:
						label: 'White'
					black:
						label: 'Black'
					asian:
						label: 'Asian'
					multi:
						label: 'Mixed'
					other:
						label: 'Other'

			occupation: new StackedBarChart 
				width: Settings.barGraphWidth
				height: 120
				name: 'occupation'
				legendData:
					management:
						label: 'Management'
					service:
						label: 'Service'
					office:
						label: 'Office'
					construction:
						label: 'Construction'
					manufacturing:
						label: 'Production'

		histogram:

			x: null
			y: null
			layout: null
			height: null
			currentData: null
			selector: '#risk-histogram'
			$container: -> $(@selector)

			$rects: ->
				$(@selector).find(".bar rect")

			update: ->
				features = ILC.visibleIndustrialFeatures
				values = features.map (f) -> f.risk()

				# maxval = Math.max.apply( Math, values )
				# @x.domain([0, maxval])
				# @layout.bins(@x.ticks(20))

				data = @layout(values) 

				if(IndustrialPolygon.activeFeature?)
					risk = IndustrialPolygon.activeFeature.risk()
					d.active = d.x <= risk && risk <= d.x + d.dx for i, d of data

				@setData(data)
				@updateActive()

			setData: (data) ->

				bar = d3.selectAll("#{ @selector } .bar")
					.data(data)
				@currentData = data

				bar.transition().duration(777)
					.attr("transform", (d) => "translate(" + @x(d.x) + "," + @y(d.y) + ")" )
					.select('rect')
						.attr( 'height', (d) => @barHeight - @y(d.y) )
						.attr( 'fill', (d) -> 
							if d.active
								Settings.activeColor
							else
								ILC.colormap().getColorString(d.x) 

					)

			updateActive: ->
				if(IndustrialPolygon.activeFeature?)
					risk = IndustrialPolygon.activeFeature.risk()
					d.active = d.x <= risk && risk <= d.x + d.dx for i, d of @currentData
				else
					d.active = false for i, d of @currentData
				@setData(@currentData)


			initialize: ->
				sz = Settings.histogramMaxValue
				# values = d3.range(1000).map( (x) -> sz * d3.random.irwinHall(10)(x) )
				values = d3.range(1000).map (x) -> 0

				# A formatter for counts.
				formatCount = d3.format(",.0f");

				axisSpace = 25
				margin = {top: 0, right: 20, bottom: 20, left: 20}
				width = Settings.graphWidth
				height = width / 2
				barHeight = height

				x = d3.scale.linear()
				    .domain([0, sz])
				    .range([0, width])

				# Generate a histogram using twenty uniformly-spaced bins.
				hist = d3.layout.histogram()
				    .bins(x.ticks(20))
				    .frequency(false)

				data = hist(values)

				y = d3.scale.linear()
				    .domain([0, 1 ])
				    .range([barHeight, 0]);

				xAxis = d3.svg.axis()
				    .scale(x)
				    .orient("bottom")
				    .ticks(1)
				    .tickFormat(d3.format("p"))
					.tickSubdivide(0.25)

				svg = d3.select(@selector).append("svg")
				    .attr("width", width + margin.left + margin.right)
				    .attr("height", height + margin.top + margin.bottom)
				  .append("g")
				    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

				bar = svg.selectAll(".bar")
				    .data(data)
				  .enter().append("g")
				    .attr("class", "bar")
				    .attr("transform", (d) -> "translate(" + x(d.x) + "," + y(d.y) + ")" )

				bar.append("rect")
				    .attr( "x", 1 )
				    .attr( "width", x(data[0].dx) - 1 )
				    .attr( "height", (d) -> barHeight - y(d.y) )
				    .attr( 'stroke', '#333' )
				    .attr( 'stroke-width', 1 )
				    .attr( 'fill', (d) -> ILC.colormap().getColorString(d.x) )

				# bar.append("text")
				#     .attr("dy", ".75em")
				#     .attr("y", 6)
				#     .attr("x", x(data[0].dx) / 2)
				#     .attr("text-anchor", "middle")
				#     .text( (d) -> formatCount(d.y) );

				svg.append("g")
				    .attr("class", "x axis")
				    .attr("transform", "translate(" + 0 + "," + barHeight + ")")
				    .call(xAxis);

				@x = x
				@y = y
				@layout = hist
				@currentData = data
				@height = height
				@barHeight = barHeight




slugs =
	polygons: (dataset) -> 'industrial-polygons-' + dataset












# class Polygon

# 	id: null
# 	L: null

# 	constructor: (coords) ->
# 		@coords = coords[..]
# 		@L = new L.Polygon(coords)

# 	centroid: ->
# 		len = @coords.length
# 		sum = @coords.reduce (a, b)->
# 			[a[0] + b[0], a[1] + b[1]]
# 		ret = sum.map (x)->
# 			x / len
# 		ret

# 	@makeList: (coord_list) ->
# 		coord_list.map (coords)->
# 			new Polygon(coords)

