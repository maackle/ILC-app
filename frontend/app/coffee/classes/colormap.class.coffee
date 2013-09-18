
class Colormap

	@loaded: []
	@currentIndex: null
	@currentNumLevels: Settings.initialColorBins
	@currentSegmentation: 'linear'

	levels: [] 		# must be in DECREASING order
	colorLo: null
	colorHi: null
	valLo: null
	valHi: null

	# @makeV1: (colorLo, colorHi, valLo, valHi, N) ->
	# 	levels = []
	# 	for i in [0..N-1]
	# 		r = parseFloat(i) / (N-1)
	# 		level = [lerp(valLo, valHi, r), lerpColor(colorLo, colorHi, r)]
	# 		levels.push level
	# 	new Colormap(levels.reverse())

	@makeV2: (swatch, riskRange) ->
		N = swatch.length
		[valLo, valHi] = riskRange
		levels = for rgb, i in swatch
			r = parseFloat(i) / (N)
			thresh = lerp(valLo, valHi, r)
			[thresh, rgb]
		new Colormap levels.reverse(), valLo, valHi

	@makeV3: (swatch, segmentation) ->
		N = swatch.length
		if segmentation=='quantile'
			risks = (f.risk() for i, f of ILC.industrial.items when f.risk()?).sort()
			[valLo, valHi] = [risks[0], risks[risks.length-1]]
			total = risks.length
			levels = for rgb, i in swatch
				q = parseInt(total * i / N)
				thresh = risks[q]
				[thresh, rgb]
		else
			[valLo, valHi] = ILC.getRiskRange()
			levels = for rgb, i in swatch
				r = parseFloat(i) / (N)
				thresh = lerp(valLo, valHi, r)
				[thresh, rgb]
		new Colormap levels.reverse(), valLo, valHi

	@updatePreviews: (N, segmentation) ->
		if ! N?
			N = Colormap.currentNumLevels
		if ! segmentation?
			segmentation = Colormap.currentSegmentation
		else
			Colormap.currentSegmentation = segmentation
		@loaded = for swatch in window.swatches
			@makeV3(swatch[N], segmentation)
		$el = $('#colormap-picker .colormaps')
		$el.html('')
		$el.append(cmap.previewHTML(i)) for cmap, i in @loaded
		$('#colormap-picker .colormap-preview[data-id='+@currentIndex+']').addClass('current')
		Colormap.currentNumLevels = N

	@setCurrent: (i)->
		@currentIndex = i
		$('#colormap-picker .colormap-preview').removeClass('current')
		$('#colormap-picker .colormap-preview[data-id='+i+']').addClass('current')


	constructor: (@levels, @valLo, @valHi) ->


	getColor: (val) ->
		if ! val?
			return Settings.noDataColor
		for lvl in @levels
			[thresh, rgb] = lvl
			if val >= thresh
				return rgb
		console.warn "value too low: #{val}"
		return @levels[@levels.length-1][1]

	getColorString: (val) ->
		[r, g, b] = @getColor(val)
		"rgb(#{r},#{g},#{b})"

	legendHTML: ->
		precision = 4
		lastThresh = (@valHi * 100).toFixed(0)

		$div = $('<ul class="legend colormap-legend"></ul>')
		lis = []
		for lvl in @levels
			[thresh, rgb] = lvl
			[r, g, b] = rgb
			colorString = "rgb(#{r},#{g},#{b})"
			# thresh = thresh.toPrecision(precision)
			thresh = (thresh * 100).toFixed(0)
			text = 
				if lastThresh?
					"#{thresh}% - #{lastThresh}%"
				else
					"#{thresh}+"
			lis.push("""
				<li>
					<div class="color" style="background: #{ colorString }"></div>
					<div class="label">#{ text }</div>
				</li>
			""")
			lastThresh = thresh
		for li in lis.reverse()
			$div.append(li)
		$div.append("""
			<li>
				<div class="color no-fill" style="border: 3px solid #{ Settings.noDataColor }; background: rgba(40, 40, 40, 0.05);"></div>
				<div class="label">No Data</div>
			</li>
		""")
		$div

	previewHTML: (id)->
		precision = 3
		lastThresh = null

		$div = $("""<ul class="colormap-preview" data-id="#{ id }"></ul>""")
		lis = []
		for lvl in @levels
			[thresh, rgb] = lvl
			[r, g, b] = rgb
			colorString = "rgb(#{r},#{g},#{b})"
			lis.push("""
				<li>
					<div class="color" style="background: #{ colorString }"></div>
				</li>
			""")
		for li in lis.reverse()
			$div.append(li)
		$div

window.Colormap = Colormap
