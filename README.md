Making Room for Manufacturing
=============================

*last updated: 16-10-2013*

Overview
--------

The map visualization application seen on this site, henceforth known as *the app*, is a completely static website, meaning it can be run anywhere with no special server requirements.  However, these static pages need to be built, and the data needs to be pulled from many sources, processed, and converted to formats useable by the app.  All of this is done automatically.

Directory Structure
-------------------

It helps to understand how the project is laid out.  Here is a rundown of some important subdirectories of the project:

- `conf/` contains the configuration files with the information needed to process the data, including file paths and other settings
- `frontend/` deals with creating the necessary HTML, Javascript and CSS
	- `frontend/app/` contains Jade, Coffeescript, and Sass source files which are used to build HTML, Javascript, and CSS, respectively.  We use [Grunt](http://gruntjs.com/) to manage these builds.
	- `frontend/www/` is the build directory, which contains the final generated, ready-to-run website
- `lib/` contains some third-party libraries needed for data processing
- `rawdata/` contains the source data in the form shapefiles, map tiles, and CSVs, which processed and fed to the app.  Some of these files are very large, so you can obtain them separately as a downloadable .ZIP.


Environment setup
=================

Various files need to be built when adding new data or modifying the website.  `make.py` in the top-level directory is used for all tasks related to data regeneration, and [Grunt](http://gruntjs.com/) is used to build frontend HTML, JS, and CSS, as well as to run a development server

Frontend setup
--------------

Refer to Grunt's website for installation instructions, which will also require installing `npm`.  Then run these commands from the project directory: 

	sudo npm install -g bower
	npm install
	bower install

If all goes well, simply run

	grunt

and the frontend will be generated and a server will start running at port 1337.  Go to http://localhost:1337 to see it.

To run the app on a server, simply host `frontend/www`.  During development, all files will be built here as well, so this is the only location you need to serve.

Data pipeline setup
-------------------

The data processing phase is done with a combination of Python and SQL backed by Spatialite.  If you want to add or otherwise manipulate the data used in the app, you'll need to follow these steps.

# Python setup

First, it is HIGHLY recommended that you first set up a [`virtualenv`](https://pypi.python.org/pypi/virtualenv)

You can install almost all package dependencies with `pip` as such:

	pip install -r requirements.txt

However, you will have to build pyspatialite from source because its pypi repository is broken (as of 9/2013), which you can also easily do with `pip`.

# Spatialite setup

You will need Spatialite 3.x (source for Spatialite 3.0.1 is included in `lib/`).  Other versions will not work, because pyspatialite depends on 3.x.  Build it from source or build it with your package manager if you can, however as of 9/2013, I've had no luck with that.

The data pipeline
=================

Configuration
-------------

All configuration is handled by `conf/projects.py` and `conf/settings.py`.  Examine them, along with the contents of `rawdata/` and `frontend/www/data` to get an idea of how source and destination data files, respectively, are laid out.

Building
--------

`make.py` is a handly little build script that can do everything you should need for making shapefiles and other raw data usable by the app.  It is invoked like this:

	python make.py <command> [projectname ...]

It is still somewhat in development and doesn't represent a stable API, the interface is subject to change.  Valid values of `<command>` are as follows:

- `load-global` - Loads global shapefiles into database, e.g. census demographic data, brownfields
- `load` - Loads project-specific shapefiles, like industrial and converted parcels
- `localize-{brownfields|demography}` - Creates a subset of the global set that only covers the project region
- `process-demography` - A computationally intensive operation that must be run after `localize-demography`
- `generate-{brownfields|industrial|converted|naics}` - The finals steps, these compile the data to JSON or GeoJSON and place them into the `frontend/www` directory

Here is the sequence of commands that was used to build the entire current data set:

	python make.py load-global
	python make.py load meck cook
	python make.py localize-brownfields meck cook
	python make.py localize-demography meck cook
	python make.py process-demography meck cook
	python make.py generate-brownfields meck cook
	python make.py generate-converted meck cook
	python make.py generate-industrial meck cook
	python make.py generate-naics meck cook

Namely, this takes all necessary data from `rawdata/` and places the processed files into `frontend/www/data`