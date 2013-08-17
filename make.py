import os
from os import path
import argparse

from conf import settings
from conf.projects import projects, global_data
from util import load_shapefile, lazy_mkdir

def load_global_shapefiles():
    filename = settings.SPATIALITE_DB_FILE
    os.remove(filename)
    for name, path in global_data.items():
        load_shapefile(name, path, settings.SPATIALITE_GLOBAL_TABLE_PREFIX)


def load_project_shapefiles(*names):
    if not names:
        print "Please specify the names of projects you want to load."
        print "Did nothing..."
    for name in names:
        assert name in map(lambda p: p.name, projects), "Invalid project name"
    for name in names:
        project = filter(lambda p: p.name == name, projects)[0]
        project.load_shapefiles()

def load_all():
    load_global_shapefiles()
    project_names = map(lambda p: p.name, projects)
    load_project_shapefiles(*project_names)

def build():
    '''
    Do everything!
    '''
    lazy_mkdir(settings.APP_DATA_DIR)  # main project dir

    for project in projects:
        lazy_mkdir(project.app_data_dir)

tasks = {
    'build': build,
    'load': load_project_shapefiles,
    'load-global': load_global_shapefiles,
    'load-all': load_all,
}

def main():

    parser = argparse.ArgumentParser(
        description='Manage the backend.'
    )
    parser.add_argument(
        'task',
        type=str,
        # nargs=1,
        help='see below for list of tasks',
        choices=tasks.keys()
    )
    parser.add_argument(
        'param',
        type=str,
        nargs='*',
    )
    args = parser.parse_args()
    method = tasks.get(args.task, build)
    method(*args.param)


if __name__ == '__main__':
    main()
