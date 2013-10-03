#_require http.coffee
#_require ILC.coffee

$ ->
# 	$('#colormap-picker .toggler').popover
# 		content: $('#colormap-picker .content').html()
# 		html: true
# 		placement: 'top'
# 		trigger: 'click'

	datasetFromHash = window.location.hash.substring(1) or 'meck'

	if google? then geocoder = new google.maps.Geocoder();

	$('#legends-and-colormaps .toggle-colormaps').click (e) ->
		if $(this).hasClass('active')
			$('#colormap-picker').fadeOut()
			$(this).text("Show colormap picker")
		else
			$('#colormap-picker').fadeIn()
			$(this).text("Hide colormap picker")

	$('#colormap-picker select.num-bins').change (e) ->
		N = $(this).val()
		IndustrialPolygon.clearActive()
		ILC.graphs.hideNonHistogram()
		Colormap.updatePreviews(N, null)
		ILC.resetLegend()
		ILC.updateFeatures()
		ILC.graphs.histogram.update()

	$('#colormap-picker .colormaps').on 'click', '.colormap-preview', (e) ->
		id = $(this).attr('data-id')
		seg = $(this).attr('data-segmentation')
		# IndustrialPolygon.clearActive()
		Colormap.setCurrent(id)
		ILC.resetLegend()
		ILC.updateFeatures()
		ILC.graphs.histogram.update()

	$('#colormap-picker select.segmentation').change (e) ->
		seg = $(this).val()
		IndustrialPolygon.clearActive()
		ILC.graphs.hideNonHistogram()
		Colormap.updatePreviews(null, seg)
		ILC.resetLegend()
		ILC.updateFeatures()
		ILC.graphs.histogram.update()

	$('.risk-select').on 'change', (e) ->
		IndustrialPolygon.riskType = $(this).val()
		IndustrialPolygon.clearActive()
		ILC.graphs.hideNonHistogram()
		Colormap.updatePreviews(null, null)
		ILC.resetLegend()
		ILC.updateFeatures()
		ILC.graphs.histogram.update()
		
		suffix = switch IndustrialPolygon.riskType
			when 'risk_res' then ' to Residential'
			when 'risk_com' then ' to Commercial'
			else ''
		$('.legend-container.industrial-parcels .title').html('Probability of conversion<br/>from Industrial' + suffix)

	$('.industry-select').on 'change', (e) ->
		val = $(this).val().substr(0,3) or null
		$(this).val(val).trigger("liszt:updated")
		ILC.currentNAICS3 = val
		ILC.updateVisibleFeatures()

	$('.togglable-panel').each (i, el) ->
		parent = $(el)
		parent.find('a.collapse').on 'click', (e) ->
			parent.find('.collapsed').show()
			parent.find('.expanded').hide()
			false
		parent.find('a.expand').on 'click', (e) ->
			parent.find('.collapsed').hide()
			parent.find('.expanded').show()
			false


	vec_btn_container = $('#vector-picker .vector-choices')
	vec_btn_container.find('.btn').on 'click', (e) ->
		key = $(this).attr('data-id')
		if $(this).hasClass 'active'
			ILC.removeVector key
		else
			ILC.addVector key

	# TODO use bounds and individual options
	$('#raster-picker .raster-choices .clear-all').on 'click', (e) ->
		$('#raster-picker .raster-choices input').attr('checked', false)
		ILC.setRaster ''
	$('#raster-picker .raster-choices input').on 'change', (e) ->
		key = $(this).attr('data-id')
		fmt = $(this).attr('data-fmt')
		if key != ILC.currentRasterKey
			opts = 
				minZoom: Settings.baseMinZoom
				maxZoom: Settings.rasterMaxZoom
				opacity: 1.0
				# bounds: [[34.97780000323601, -81.08615238986796], [35.42838178194739, -80.56556496757148]]
			if ILC.dataset == 'meck'
				opts.tms = true
			ILC.setRaster key, fmt, opts
				
	$('#address-picker form').on 'submit', (e) ->
		e.preventDefault()
		address = $(this).find('.address').val()
		if geocoder?
			geocoder.geocode
				address: address
				(results, status) ->
					loc = results[0].geometry.location
					latlng = [loc.jb, loc.kb]
					ILC.map.setView latlng, 14
		else
			console.error "google geocoder failed to load"
		false

	for abbr, label of Settings.convertedCategories[datasetFromHash]
		color = Settings.convertedColors[datasetFromHash][abbr]
		$('.legend-container.converted-parcels ul.legend').append("""
			<li>
				<div class="color" style="border: 3px solid #{color}"></div>
				<div class="label">#{label}</div>
			</li>
		""")


	HTTP.setup()

	$('#control-panels .left').children().each ->
		$('.leaflet-control-container .leaflet-left.leaflet-top').append($(this))

	console.log("here we go")
	
	$ ->
		ILC.initialize
			dataset: datasetFromHash
			limit: 500
		
