#_require settings.coffee
#_require classes/barchart.class.coffee
#_require classes/colormap.class.coffee
#_require classes/convertedpolygon.class.coffee
#_require classes/feature.class.coffee
#_require classes/feature2d.class.coffee
#_require classes/industrialpolygon.class.coffee
#_require classes/multipolygoncollection.class.coffee

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
		"old-data/#{ dataset }"

	initialize: (opts) ->
		{dataset, limit} = opts
		@initLeaflet('leaflet-map')
		ILC.addPolygons(dataset, limit)
		ILC.loadData(dataset)
		@graphs.naics_trends.initialize()
		@graphs.histogram.initialize()
		@graphs.demography.race.initialize()
		@graphs.demography.occupation.initialize()
		@pxScale()
		

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
		size = Math.max(4, (zoom - 11)*2 + 6)
		$('.brownfield-divicon').css
			width: size
			height: size
			'margin-left': -size/2
			'margin-top': -size/2

	resetLegend: ->
		$('#legend .colormap').html('').append(@colormap().legendHTML())

	# OPTIMIZE: only update features that were added
	updateVisibleFeatures: ->
		previousNum = @visibleIndustrialFeatures.length
		group = ILC.industrial
		group.L.clearLayers()
		pxScale = @pxScale()

		@visibleIndustrialFeatures = 
			for id, f of group.items when f.size_metric * pxScale > Settings.minSizeMetric and (@currentNAICS3 == null or f.naics3 == @currentNAICS3)
				f.pxSizeEstimate = f.size_metric * pxScale
				group.L.addLayer(f.L)
				f
		if @colormap()? and @visibleIndustrialFeatures.length > previousNum
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
			urlTemplate = "images/tiles/#{ id }/{z}/{x}/{y}.#{ fmt }"
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


		map = @map
		limit_str = 
			if limit?
				'?limit='+limit
			else
				''


		url_industrial = @datapath(dataset) + '/json/development-polygons-all.json'
		url_converted = @datapath(dataset) + '/json/converted-polygons-all.json'
		res = HTTP.blocking 'GET', url_industrial #TODO: make async
		res.success (data) =>
			multipolygons = data.multipolygons[1..limit]
			@industrial = new MultiPolygonCollection('industrial', multipolygons)
			bounds = @industrial.L.getBounds()
			map.fitBounds(bounds)
			@industrial.L.addTo(map)
			ILC.vectorLayers['industrial-parcels'] = @industrial.L
			@updateVisibleFeatures()
			calculateStuff(@visibleIndustrialFeatures)

		res = HTTP.blocking 'GET', url_converted #TODO: make async
		res.success (data) =>
			multipolygons = data.multipolygons[1..limit]
			@converted = new MultiPolygonCollection('converted', multipolygons)
			ILC.vectorLayers['converted-parcels'] = @converted.L
			# @converted.L.addTo(@map)

	loadData: (dataset)->
		# res = HTTP.blocking 'GET', '/api/charlotte/industrial/naics-trends'
		res = HTTP.blocking 'GET', @datapath(dataset) + '/json/development-naics-trends.json'
		res.success (data) =>
			@naics_trends = data.naics_trends

		res = HTTP.blocking 'GET', @datapath(dataset) + '/json/naics-list.json'
		res.success (data) =>
			@naics_list = data.naics_list

		res = HTTP.blocking 'GET', @datapath(dataset) + '/json/brownfields.geojson'
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
				total: null
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
				@lines.total = d3.svg.line()
					.x( (d) => @x(d.year) )
					.y( (d) => @y(d.value) )

				@svg = d3.select('#naics-trends-graph')
					.append('svg:svg')
						.attr('width', width)
						.attr('height', height)
					.append('g')
						.attr 'transform', "translate(#{ margin.left }, #{ margin.top })"

				lineStyle = (name) -> 
					fill: 'none'
					class: name
					stroke: (
						if name=='county' then makeColorString(Settings.graphs.trends.colors[0])
						else if name=='state' then makeColorString(Settings.graphs.trends.colors[1])
						else makeColorString(Settings.graphs.trends.colors[2])
					)

				@svg.append('path').attr(lineStyle('county'))
				@svg.append('path').attr(lineStyle('state'))
				@svg.append('path').attr(lineStyle('total'))

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
				else
					@hide()
					return

				naicsTitle = ILC.naics_list[naics_code]

				@$container().find('.info .naics-title').text("#{naics_code} - #{naicsTitle}")
				@$container().find('.naics').text("#{naics_code}")
				@$container().find('.info .naics-filter-select').click (e) ->
					$('.industry-select').val(naics_code)
					$('.industry-select').trigger("liszt:updated");
					ILC.currentNAICS3 = naics_code.substr(0, 3)
					ILC.updateVisibleFeatures()
					false

				countywide = ILC.naics_trends.countywide[naics_code]
				statewide = ILC.naics_trends.statewide[naics_code]

				data =
					county:   countywide.emp_growth
					state:    statewide.emp_growth
					total:    ILC.naics_trends.statewide_total.emp_growth

				meta = 
					county:
						baseYear: countywide.base_year
					state:
						baseYear: statewide.base_year
					total:
						baseYear: 1990

				baseYear = Math.max(countywide.base_year, statewide.base_year)
				# baseYear = parseInt(Math.random() * 20 + 1990)
				baseIndex = baseYear - 1990
				baseX = @x(baseYear)

				min = 999
				max = -999
				for k, datum of data
					for d in datum
						if baseIndex > 0
							d.value /= datum[baseIndex].value
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
					islander:
						label: 'Islander'
					native:
						label: 'Native American'
					asian:
						label: 'Asian'
					mixed:
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
					production:
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
				mapBounds = ILC.map.getBounds()
				features = (f for f in ILC.visibleIndustrialFeatures when f.risk()? and f.L.getBounds().intersects(mapBounds))
				values = features.map (f) -> f.risk()

				# maxval = Math.max.apply( Math, values )
				# @x.domain([0, maxval])
				# @layout.bins(@x.ticks(20))

				data = @layout(values) 

				console.log IndustrialPolygon.activeFeature?
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
				values = d3.range(1000).map( (x) -> sz * d3.random.irwinHall(10)(x) );

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












class Polygon

	id: null
	L: null

	constructor: (coords) ->
		@coords = coords[..]
		@L = new L.Polygon(coords)

	centroid: ->
		len = @coords.length
		sum = @coords.reduce (a, b)->
			[a[0] + b[0], a[1] + b[1]]
		ret = sum.map (x)->
			x / len
		ret

	@makeList: (coord_list) ->
		coord_list.map (coords)->
			new Polygon(coords)
