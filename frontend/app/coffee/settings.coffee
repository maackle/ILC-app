
window.Settings =
	histogramMaxValue: 1.0
	initialColorBins: 5
	fillOpacity: 0.9
	activeColor: '#4c4'
	noDataColor: '#666'
	debugLimit: 500
	minSizeMetric: 5
	baseMinZoom: 10
	rasterMaxZoom: 13
	brownfieldSmallZoom: 12
	graphWidth: 180
	barGraphWidth: 50
	lineGraphHeight: 125
	maxVisibleFeatures: 1000

	DEBUG_MODE: false	# limit number of polygons to 1000 or so


	graphs:
		trends:
			colors: [[251,128,114], [100, 222, 60], [10, 10, 10]]  # must also change in css

	panOnActivate: true

	useLocalData: false
	useDemography: true  # set false if you don't care about demography for now
	requireDemography: true  # set false to not show features without non-null demography (race at least) data
	switchLatLng: true  # if incoming polygon data is longitude, latitude
	skipBrownfields: false

	baseStyle: ->
		weight: 1
		color: '#333'
		opacity: 0.5

	activeStyle: ->
		fillOpacity: 1.0
		fillColor: @activeColor
		weight: 3
		opacity: 1.0

	hoverStyle: ->
		fillOpacity: 1.0
		weight: 2
		opacity: 1.0

	colors:
		race: [
			'rgb(255, 255, 179)'
			'rgb(141, 211, 199)'
			'rgb(190, 186, 218)'
			'rgb(251, 128, 114)'
			'rgb(128, 177, 211)'
			'rgb(253, 180, 98)'
			'rgb(179, 222, 105)'
		]
		occupation: [
			'rgb(255, 255, 179)'
			'rgb(141, 211, 199)'
			'rgb(190, 186, 218)'
			'rgb(251, 128, 114)'
			'rgb(128, 177, 211)'
			'rgb(253, 180, 98)'
			'rgb(179, 222, 105)'
		]

Settings.convertedColors =
	cook:
		'R': 'rgb(0, 200, 0)',
		'C': 'rgb(255, 0, 0)',
		# 'I': 'magenta',
		# 'AG': 'magenta',
		# 'OS': 'magenta',
		# 'TCU': 'magenta',
		'OTH': 'magenta',
		'NON': Settings.noDataColor,
	meck:
		'SFR': 'rgb(0, 200, 0)',
		'MFR': 'rgb(0, 100, 0)',
		'COM': 'rgb(255, 0, 0)',
		'OFF': 'rgb(0, 0, 200)',
		'OTH': 'rgb(200, 0, 200)',
		'NON': Settings.noDataColor,

Settings.convertedCategories =
	cook:
		'R': 'Residential',
		'C': 'Commercial',
		# 'I': 'Industrial ???',
		# 'AG': 'Agriculture ???',
		# 'OS': 'OS ???',
		# 'TCU': 'TCU ???',
		'OTH': 'Other',
		'NON': 'No Data',
	meck:
		'SFR': 'Single Family Residential',
		'MFR': 'Multi Family Residential',
		'COM': 'Commercial',
		'OFF': 'Office',
		'OTH': 'Other',
		'NON': 'No Data',



window.lerp = (a, b, f) ->
    a + f * (b - a)

window.lerpColor = (a, b, f) ->
	[
		lerp(a[0], b[0], f),
		lerp(a[1], b[1], f),
		lerp(a[2], b[2], f)
	]

window.makeColorString = (rgb) ->
	[r, g, b] = rgb
	"rgb(#{r},#{g},#{b})"

