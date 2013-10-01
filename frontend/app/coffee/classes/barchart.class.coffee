
class StackedBarChart

	color: null
	svg: null
	$container: null
	opts: {}

	constructor: (@opts) ->
		@legendData = @opts.legendData
		@name = @opts.name
		@id = "#{@name}-pie"

	initialize: ->
		width = @opts.width
		height = @opts.height || @opts.width
		@$container = $("##{@id}")
		@svg = d3.select("##{@id} .graph")
			.append("svg:svg")			  # create the SVG element inside the <body>
				.attr("width", width)		   # set the width and height of our visualization (these will be attributes of the <svg> tag
				.attr("height", height)
			.append("svg:g")				# make a group to hold our pie chart


		@layout = (data) ->
			sum = data.map((d) -> d.population).reduce (a, b) -> a + b
			prev = 0
			out = for d in data
				val = height * d.population / sum
				obj =
					width: width
					height: val
					y: +prev
					data: d
				prev += val
				obj
			return out

		i = 0
		for key, slice of @legendData
			@legendData[key].color = Settings.colors.race[i++]
		legend = @$container.find('ul.legend')
		for key, slice of @legendData
			li = $("""
				<li class="#{ key }">
					<div class="color" style="background: #{ slice.color }"></div>&nbsp;<div class="label">#{ slice.label }</div>
				</li>
			""")
			legend.append li
		@$container.append('<br class="clear"/>')

	setFeature: (f) ->
		values = for k, v of f.properties.demography[@name]
			if v == 0
				@$container.find("li.#{k}").fadeOut()
			else
				@$container.find("li.#{k}").fadeIn()
			{name: k, population: v}
		@setData(values)
		@$container.fadeIn()

	hide: ->
		@$container.fadeOut()

	setData: (values)->
		data = @layout(values)
		slice = @svg.selectAll("g.slice")
			.data(data, (d)=> d.data.name)

		slice.transition().duration(777)
			.select('rect')
				.attr("y", (d) -> d.y)
				.attr("height", (d) -> d.height)

		rects = slice.enter()							# this will create <g> elements for every "extra" data element that should be associated with a selection. The result is creating a <g> for every object in the data array
			.append("svg:g")				# create a group to hold each slice (we will have a <path> and a <text> element associated with each slice)
				.attr("class", "slice")
				.append("svg:rect")
					.attr("fill", (d) => @legendData[d.data.name].color ) # set the @color for each slice to be chosen from the @color function defined above
					.attr("width", (d) -> d.width)
					.attr("y", (d) -> d.y)
					.attr("height", (d) -> d.height)
					.each( (d) -> this._current = d )

window.StackedBarChart = StackedBarChart