import os
from os import path
import argparse

from conf import settings
from conf.projects import projects, global_data

def lazy_mkdir(path):
	try:
		os.mkdir(path)
	except OSError:
		pass

def load_global_shapefiles():

	for name, path in global_data.items():
		line = ".loadshp {shp} {name} {encoding} {srid} {geom_column_name}".format(
			name=name,
			shp=path,
			encoding=settings.SPATIALITE_ENCODING,
			srid=settings.SPATIALITE_SRID,
			geom_column_name=settings.SPATIALITE_GEOMETRY_COLUMN_NAME,
		)
		os.system("echo \"{line}\" | spatialite {file}".format(
			line=line,
			file=settings.SPATIALITE_DB_FILE,
		))

def build():

	lazy_mkdir(settings.APP_DATA_DIR)  # main project dir

	for project in projects:
		lazy_mkdir(project.app_data_dir)


tasks = {
	'build': build,
	'load-global': load_global_shapefiles,
}

def main():

	parser = argparse.ArgumentParser(
		description='Manage the backend.'
	)
	parser.add_argument(
		'task',
		type=str,
		nargs='?',
		help='see below for list of tasks',
		choices=tasks.keys()
	)
	args = parser.parse_args()
	method = tasks.get(args.task, build)
	method()


if __name__ == '__main__':
	main()
