module.exports = (grunt) ->

	# Project configuration.
	grunt.initConfig
		pkg: grunt.file.readJSON('package.json')

		config:
			app: 'app'
			dist: 'www'

		connect:
			server:
				options:
					port: 1337
					base: '<%= config.dist %>'

		watch:
			coffee:
				files: ["<%= config.app %>/coffee/{,**}/*.coffee"]
				tasks: ['coffee']
			compass:
				files: ["<%= config.app %>/sass/{,**}/*.{sass,scss}"]
				tasks: ['compass']
			jade:
				files: ['<%= config.app %>/jade/{,**}/*.jade']
				tasks: ['jade']

		coffee:
			options:
				join: true
			compile:
				files:
					"<%= config.dist %>/scripts/main.js": [
						"<%= config.app %>/coffee/graph.coffee",
						"<%= config.app %>/coffee/app.coffee",
						"<%= config.app %>/coffee/http.coffee",
						"<%= config.app %>/coffee/settings.coffee",
						"<%= config.app %>/coffee/choropleth-swatches.coffee",
						"<%= config.app %>/coffee/classes/barchart.class.coffee",
						"<%= config.app %>/coffee/classes/colormap.class.coffee",
						"<%= config.app %>/coffee/classes/polygon.class.coffee",
						"<%= config.app %>/coffee/classes/feature.class.coffee",
						"<%= config.app %>/coffee/classes/feature2d.class.coffee",
						"<%= config.app %>/coffee/classes/industrialpolygon.class.coffee",
						"<%= config.app %>/coffee/classes/convertedpolygon.class.coffee",
						"<%= config.app %>/coffee/classes/multipolygoncollection.class.coffee",
						"<%= config.app %>/coffee/ILC.coffee",
						"<%= config.app %>/coffee/app-init.coffee",
					] # // compile and concat into single file

		compass:
			dist:
				options:
					sassDir: "<%= config.app %>/sass/",
					cssDir: "<%= config.dist %>/styles/",
					environment: 'production'

		jade:
			dist:
				options:
					pretty: true
				files: [{
					expand: true,
					cwd: '<%= config.app %>/jade'
					dest: "<%= config.dist %>"
					src: '*.jade'
					ext: '.html'
				}]

		# copy:
		#     dist:
		#         files: [
		#             {
		#                 expand: true
		#                 cwd: 'data'
		#                 src: '**'
		#                 dest: 'www/data'
		#             }
		#         ]

	grunt.loadNpmTasks('grunt-contrib-coffee')
	grunt.loadNpmTasks('grunt-contrib-copy')
	grunt.loadNpmTasks('grunt-contrib-watch')
	grunt.loadNpmTasks('grunt-contrib-compass')
	grunt.loadNpmTasks('grunt-contrib-jade')
	grunt.loadNpmTasks('grunt-contrib-connect')
	grunt.loadNpmTasks('grunt-notify')

	#// Default task(s).
	grunt.registerTask 'default', [
		'build'
		'connect'
		'watch'
	]

	grunt.registerTask 'build', [
		'copy:dist'
		'jade:dist'
		'coffee:compile'
		'compass:dist'
	]