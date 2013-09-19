
window.Settings =
	histogramMaxValue: 0.5
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

	graphs:
		trends:
			colors: [[251,128,114], [100, 222, 60], [10, 10, 10]]

	panOnActivate: true

	useLocalData: false
	useDemography: false  # don't care about demography for now
	switchLatLng: true  # if incoming polygon data is longitude, latitude

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

