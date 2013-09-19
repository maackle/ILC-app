
class IndustrialPolygon extends Feature2D

	L: null
	baseColor: null
	components: null
	@activeFeature: null

	@infoPopup: new L.Popup
		offset: L.point(0, -4)

	@riskType: 'risk_main'
	
	@setActive: (f, dom_event)->
		@clearActive(dom_event)
		@activeFeature = f
		# if dom_event?
		# 	$el = $(dom_event.toElement)
			# $el.addClass('fast-transition')
		f.L.setStyle Settings.activeStyle()
		ILC.graphs.demography.race.setFeature(f)
		ILC.graphs.demography.occupation.setFeature(f)
		ILC.graphs.naics_trends.setNAICS(f.naics)
		$('#legends-and-colormaps').fadeOut()
		if Settings.panOnActivate
			pos = f.centroid()
			ILC.map.panTo(pos)

	@clearActive: (dom_event)->
		if @activeFeature?
			@activeFeature.L.setStyle Settings.baseStyle()
			@activeFeature.updateColor(ILC.colormap())
			
			# if dom_event?
			# 	$el = $(dom_event.toElement)
				# $el.addClass('fast-transition')
			@activeFeature = null

	risk: ->
		if ! @risk_main? then throw "risk_main not set"
		val = switch IndustrialPolygon.riskType
			when 'risk_main' then @risk_main
			when 'risk_res' then @risk_res
			when 'risk_com' then @risk_com
			else throw "unknown risk type: " + IndustrialPolygon.riskType
		if val == 0 then return null
		else return val

	updateColor: (colormap)->
		if ! @risk()?
			# @baseColor = Settings.noDataColor
			@L.setStyle
				color: Settings.noDataColor
				fillColor: Settings.noDataColor
				fillOpacity: 0.05
				opacity: 1
				weight: 1.5
		else
			if colormap
				@baseColor = colormap.getColorString(@risk())
				@L.setStyle
					fillColor: @baseColor
					fillOpacity: Settings.fillOpacity
	
	constructor: (data) ->
		props = data.properties
		geom = data.geometry

		@gid = props.gid
		@risk_main = props.probability.risk_main
		@risk_res = props.probability.risk_res
		@risk_com = props.probability.risk_com
		@size_metric = props.size_metric
		@naics3 = props.naics.toString().substr(0,3)
		@naics4 = props.naics.toString().substr(0,4)
		@naics = @naics4

		coords = geom.coordinates
		super(coords)

		@L.obj = this

		if Settings.useDemography
			race = props.demography.race
			occupation = props.demography.occupation
			race_total = (v for i, v of race).reduce( (a,b) -> a + b )
			occupation_total = (v for i, v of occupation).reduce( (a,b) -> a + b )
			raceResidual = 0.0
			raceThreshold = 0.02
			for name, v of race
				race[name] = v / race_total
			for name, v of race
				if v < raceThreshold
					raceResidual += v
					race[name] = 0
			if raceResidual > 0
				race['other'] += raceResidual
			for name, v of occupation
				occupation[name] = v / occupation_total
		else
			race = {}
			occupation = {}

		@demography =
			race: race
			occupation: occupation

		@L
		.on 'click', (e)=>
			IndustrialPolygon.setActive(this, e.originalEvent)
		.on 'mouseover', (e)=>
			IndustrialPolygon.infoPopup
				.setLatLng(e.latlng)
				.openOn(ILC.map)
		.on 'mousemove', (e)=>
			if (not IndustrialPolygon.activeFeature? or IndustrialPolygon.activeFeature.L != e.target)
				e.target.setStyle Settings.hoverStyle()
			if this.naics? and this.naics > 0
				content = this.naics + " - " + ILC.naics_list[this.naics]
			else
				content = "<i>Industry unknown</i>"
			IndustrialPolygon.infoPopup
				.setLatLng(e.latlng)
				.setContent(content)
			$('#debug-stats.on').show().html("""
				<p>pxSizeEstimate: #{ @pxSizeEstimate }</p>
			""")
		.on 'mouseout', (e)->
			ILC.map.closePopup()
			if not IndustrialPolygon.activeFeature? or IndustrialPolygon.activeFeature.L != e.target
				e.target.setStyle Settings.baseStyle()
				e.target.obj.updateColor()
			$('#debug-stats.on').hide()

window.IndustrialPolygon = IndustrialPolygon
