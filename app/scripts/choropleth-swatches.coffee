# red-yellow-green diverging
red_yellow_green = '''
252, 141, 89; 255, 255, 191; 153, 213, 148; 
215, 25, 28; 253, 174, 97; 171, 221, 164; 43, 131, 186; 
215, 25, 28; 253, 174, 97; 255, 255, 191; 171, 221, 164; 43, 131, 186; 
213, 62, 79; 252, 141, 89; 254, 224, 139; 230, 245, 152; 153, 213, 148; 50, 136, 189; 
'''

# orange-red sequential
orange_red = '''
254, 232, 200; 253, 187, 132; 227, 74, 51; 
254, 240, 217; 253, 204, 138; 252, 141, 89; 215, 48, 31; 
254, 240, 217; 253, 204, 138; 252, 141, 89; 227, 74, 51; 179, 0, 0; 
254, 240, 217; 253, 212, 158; 253, 187, 132; 252, 141, 89; 227, 74, 51; 179, 0, 0; 
'''

# yellow-green-blue sequential
yellow_green_blue = '''
237, 248, 177; 127, 205, 187; 44, 127, 184; 
255, 255, 204; 161, 218, 180; 65, 182, 196; 34, 94, 168; 
255, 255, 204; 161, 218, 180; 65, 182, 196; 44, 127, 184; 37, 52, 148; 
255, 255, 204; 199, 233, 180; 127, 205, 187; 65, 182, 196; 44, 127, 184; 37, 52, 148; 
'''

parseLine = (line) ->
	line.split(";")
		.map($.trim)
		.filter (c) -> 
			c.length > 0
		.map (c) ->
			c.split(", ")

window.swatches = for raw in [orange_red, yellow_green_blue, red_yellow_green]
	lines = for line, i in raw.split("\n")
		parseLine(line)
	swatch = {}
	swatch[rgbs.length] = rgbs for rgbs in lines
	swatch

noDataColor = window.Settings.noDataColor

window.convertedColors = {
	'SFR': 'rgb(0, 200, 0)',
	'MFR': 'rgb(0, 100, 0)',
	'COM': 'rgb(255, 0, 0)',
	'OFF': 'rgb(0, 0, 200)',
	'OTH': 'rgb(200, 0, 200)',
	# 'NON': noDataColor,
}

window.convertedCategories = {
	'SFR': 'Single Family Residential',
	'MFR': 'Multi Family Residential',
	'COM': 'Commercial',
	'OFF': 'Office',
	'OTH': 'Other',
	# 'NON': 'No Data',
}

# TODO: move to own file, or rename this one appropriately
races7 = '''255, 255, 179; 141, 211, 199; 190, 186, 218; 251, 128, 114; 128, 177, 211; 253, 180, 98; 179, 222, 105;'''

window.raceColors = parseLine(races7)