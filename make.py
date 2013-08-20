import os
import re
import argparse
import tempfile
from subprocess import call

from conf import settings
from conf.projects import projects, global_datasets
from util import *
from sqlalchemy import create_engine
import sqlite3


def db_connect():
    engine = create_engine('sqlite://%s' % (settings.SPATIALITE_DB_FILE,))
    conn = engine.connect()
    return engine


def interpolate_sql(script, **kwargs):
    for k, v in kwargs.items():
        script = script.replace(":%s" % str(k), str(v))
    return script

def run_spatialite_script(conn, script_template, driver='sqlite', **kwargs):
    assert driver == 'sqlite', "Unsupported driver: %s" % driver
    script = interpolate_sql(script_template, **kwargs)
    print script
    fd, path = tempfile.mkstemp()
    with open(path, 'w') as f:
        f.write(script)
    os.close(fd)
    return call("spatialite {db} < {script}".format(script=path, db=settings.SPATIALITE_DB_FILE), shell=True)


def sqlite_connect():
    conn = sqlite3.connect(settings.SPATIALITE_DB_FILE)
    return conn


def get_project(name):
    return filter(lambda p: p.name == name, projects)[0]


def load_global_shapefiles():
    filename = settings.SPATIALITE_DB_FILE
    for name, data in global_datasets.items():
        load_shapefile(data['table'], data['path'], data['srid'])


def load_project_shapefiles(*names):
    if not names:
        print "Please specify the names of projects you want to load."
        print "Did nothing..."
    for name in names:
        assert name in map(lambda p: p.name, projects), "Invalid project name"
    for name in names:
        project = get_project(name)
        project.load_shapefiles()


def load_all():
    load_global_shapefiles()
    project_names = map(lambda p: p.name, projects)
    load_project_shapefiles(*project_names)


def process_demography():
    with open("sql/process-demography.sql") as f:
        script_template = "\n".join(f.readlines())
        conn = sqlite_connect()
        for project in projects:
            run_spatialite_script(conn, script_template, 
                global_demography_table=settings.DEMOGRAPHY_TABLE,
                raw_industrial_table=project.raw_industrial_table,
                occupation_table=project.occupation_table,
                race_table=project.race_table,
                equal_area_srid=settings.EQUAL_AREA_SRID,
            )


def build():
    '''
    Do everything!
    '''
    lazy_mkdir(settings.APP_DATA_DIR)  # main project dir

    for project in projects:
        lazy_mkdir(project.app_data_dir)


def main():

    tasks = {
        'build': build,
        'load': load_project_shapefiles,
        'load-global': load_global_shapefiles,
        'load-all': load_all,
        'process-demography': process_demography,
    }

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
