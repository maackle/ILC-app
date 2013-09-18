import os
import re
import sys
import argparse
import tempfile
from subprocess import call
import json

from pyspatialite import dbapi2 as sqlite3
import geojson
from shapely import wkt, wkb

from conf import settings
from conf.settings import global_datasets
from conf.projects import projects
from util import *


def interpolate_sql(script, **kwargs):
    for k, v in kwargs.items():
        script = script.replace(":%s" % str(k), str(v))
    return script

def run_spatialite_script(conn, script_template, driver='sqlite', print_script=False, **kwargs):
    assert driver == 'sqlite', "Unsupported driver: %s" % driver
    script = interpolate_sql(script_template, **kwargs)
    if print_script:
        print script
    fd, path = tempfile.mkstemp()
    with open(path, 'w') as f:
        f.write(script)
    os.close(fd)
    return call("spatialite {db} < {script}".format(script=path, db=settings.SPATIALITE_DB_FILE), shell=True)


class db_connect:
    def __enter__(self):
        self.conn = sqlite3.connect(settings.SPATIALITE_DB_FILE)
        self.conn.row_factory = sqlite3.Row
        return self.conn
    def __exit__(self, type, value, traceback):
        self.conn.close()


def get_project(name):
    assert name in map(lambda p: p.name, projects), "Invalid project name"
    return filter(lambda p: p.name == name, projects)[0]


def task_load_global_shapefiles():
    filename = settings.SPATIALITE_DB_FILE
    for name, data in global_datasets.items():
        load_shapefile(data['table'], data['path'], data['srid'])


def task_localize_demography(*names):
    if not names:
        print "Please specify the names of projects you want to load."
        print "Did nothing..."
    with open("sql/localize-demography.sql") as f:
        script_template = " ".join(f.readlines())
        with db_connect() as conn:
            for name in names:
                project = get_project(name)
                fips5_list = project.fips5_list
                if len(fips5_list) > 1:
                    fips5_list = str(fips5_list)
                elif len(fips5_list) == 1:
                    fips5_list = "({0})".format(fips5_list[0])
                else:
                    raise "no fips5_list specified"

                run_spatialite_script(conn, script_template,
                    global_demography_table=settings.DEMOGRAPHY_TABLE,
                    local_demography_table=project.raw_demography_table,
                    buffer_radius=1609*10,
                    fips5_list=fips5_list,
                )


def task_load_project_shapefiles(*names):
    if not names:
        print "Please specify the names of projects you want to load."
        print "Did nothing..."
    for name in names:
        project = get_project(name)
        project.load_shapefiles()


def task_load_all():
    task_load_global_shapefiles()
    project_names = map(lambda p: p.name, projects)
    task_load_project_shapefiles(*project_names)


def task_process_demography():
    with open("sql/process-demography.sql") as f:
        script_template = " ".join(f.readlines())
        with db_connect() as conn:
            for project in projects:
                run_spatialite_script(conn, script_template, 
                    local_demography_table=project.raw_demography_table,
                    raw_industrial_table=project.raw_industrial_table,
                    occupation_table=project.occupation_table,
                    race_table=project.race_table,
                    equal_area_srid=settings.EQUAL_AREA_SRID,
                )

def create_industrial_table(*project_names):

    with db_connect() as conn:
        with open("sql/generate-industrial.sql") as f:
            script_template = " ".join(f.readlines())
            for proj_name in project_names:
                project = get_project(proj_name)
                probs = project.industrial_parcels['probability_categories']

                probability_names = [p['name'] for p in probs]
                raw_probability_names = [p['rawname'] for p in probs]
                name_list = " ".join((name + ', ' for name in probability_names))
                rawname_list = " ".join((rawname + ', ' for rawname in raw_probability_names))
                name_with_type_list = " ".join((name + ' FLOAT, ' for name in probability_names))

                run_spatialite_script(conn, script_template,
                    table=project.industrial_table,
                    rawtable=project.raw_industrial_table,
                    probability_name_list=name_list,
                    probability_rawname_list=rawname_list,
                    probability_name_with_type_list=name_with_type_list,
                    geog_srid=settings.GEOGRAPHIC_SRID,
                )

def task_generate_industrial(*project_names):
    create_industrial_table(*project_names)
    setup_project_directories()
    with db_connect() as conn:
        for proj_name in project_names:
            project = get_project(proj_name)

            probability_names = [p['name'] for p in project.industrial_parcels['probability_categories']]
            race_names = [r['name'] for r in project.demography['race_categories']]
            occupation_names = [o['name'] for o in project.demography['occupation_categories']]

            industrial_features = []

            query_template = """
                SELECT *, AsText(geom) as geom_wkt from {industrial} i
            """
            if settings.USE_DEMOGRAPHY:
                query_template += " JOIN {race} r ON r.gid = i.gid JOIN {occupation} o ON o.gid = i.gid "

            query_template += " ORDER BY size_metric DESC "

            query = query_template.format(
                    industrial=project.industrial_table,
                    race=project.race_table,
                    occupation=project.occupation_table,
                    chunk_size=settings.FEATURE_CHUNK_SIZE,
                )

            cur = conn.execute(query)
            chunk_num = 0
            chunk = cur.fetchmany(settings.FEATURE_CHUNK_SIZE)

            json_dir = project.app_data_dir('json')
            lazy_mkdir(json_dir)

            for f in os.listdir(json_dir):
                if f.startswith('industrial-') and f.endswith('.geojson'):
                    # print f
                    os.remove(os.path.join(json_dir, f))

            while chunk:

                with open(os.path.join(json_dir, 'industrial-{0}.geojson'.format(chunk_num)), 'w') as f:

                    for row in chunk:
                        properties = {
                            'gid': row['gid'],
                            'naics': row['naics'],
                            'size_metric': row['size_metric'],
                            'probability': {},
                            'demography': {
                                'race': {},
                                'occupation': {},
                            },
                        }

                        for name in probability_names:
                            properties['probability'][name] = row[name]

                        if settings.USE_DEMOGRAPHY:
                            for name in race_names:
                                properties['demography']['race'][name] = row[name]

                            for name in occupation_names:
                                properties['demography']['occupation'][name] = row[name]

                        geom = wkt.loads(row['geom_wkt'])

                        industrial_features.append({
                            'type': 'Feature',
                            'geometry': geojson.dumps(geom),
                            'properties': properties,
                        })

                    f.write(json.dumps({
                        'type': 'FeatureCollection',
                        'features': industrial_features,
                    }))

                chunk = cur.fetchmany(settings.FEATURE_CHUNK_SIZE)
                chunk_num += 1




def setup_project_directories():
    lazy_mkdir(settings.APP_DATA_DIR)  # main project dir

    for project in projects:
        lazy_mkdir(project.app_data_dir())


def task_build():
    '''
    Do everything!
    '''
    setup_project_directories()


def main():

    tasks = {
        # 'build': task_build,
        'load': task_load_project_shapefiles,
        'load-global': task_load_global_shapefiles,
        'load-all': task_load_all,
        'localize-demography': task_localize_demography,
        'process-demography': task_process_demography,
        'generate-industrial': task_generate_industrial,
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
    method = tasks.get(args.task, task_build)
    method(*args.param)


if __name__ == '__main__':
    main()
