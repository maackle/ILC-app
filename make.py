import csv
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

def run_file_based_spatialite_script(conn, script_template, driver='sqlite', print_script=False, **kwargs):
    assert driver == 'sqlite', "Unsupported driver: %s" % driver
    script = interpolate_sql(script_template, **kwargs)
    if print_script:
        print script
    fd, path = tempfile.mkstemp()
    with open(path, 'w') as f:
        f.write(script)
    os.close(fd)
    return call("spatialite {db} < {script}".format(script=path, db=settings.SPATIALITE_DB_FILE), shell=True)


def run_spatialite_script(conn, script_template, driver='sqlite', print_script=False, **kwargs):
    assert driver == 'sqlite', "Unsupported driver: %s" % driver
    script = interpolate_sql(script_template, **kwargs)
    with db_connect() as conn:
        cur = conn.executescript(script)
        conn.commit()
    return cur


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
    for proj_name in names:
        project = get_project(proj_name)
        fips_list = project.fips_list
        if len(fips_list) > 1:
            fips_list = str(fips_list)
        elif len(fips_list) == 1:
            fips_list = "('{0}')".format(fips_list[0])
        else:
            raise "no fips_list specified"

        with db_connect() as conn:
            conn.execute("DROP TABLE IF EXISTS {local_demography_table}".format(local_demography_table=project.raw_demography_table))
            print '[{0}] Dropped local demography table'.format(proj_name)

            conn.execute("""
                CREATE TABLE {local_demography_table} AS
                    SELECT * FROM {global_demography_table}
                    LIMIT 0
                ;
            """.format(
                global_demography_table=settings.DEMOGRAPHY_TABLE,
                local_demography_table=project.raw_demography_table,
            ))
            print '[{0}] Recreated local demography table'.format(proj_name)

            fips_query = """
                select FIPS from _G_counties where intersects(geom, (select collect(geom) from _G_counties where FIPS in {fips_list}))
            """.format(
                fips_list=fips_list
            )

            extended_fips_list = "(" + ",".join("'{0}'".format(row[0]) for row in conn.execute(fips_query).fetchall()) + ")"

            cur = None
            # while not cur or cur.rowcount > 0:
            query = """
                INSERT INTO {local_demography_table}
                SELECT * FROM {global_demography_table}
                where substr(GEOID10, 1, 5) IN {extended_fips_list}
            """.format(
                global_demography_table=settings.DEMOGRAPHY_TABLE,
                local_demography_table=project.raw_demography_table,
                buffer_radius=1609*10,
                extended_fips_list=extended_fips_list,
            )
            cur = conn.execute(query)
            print "rows added:", cur.rowcount
            conn.commit()


def task_localize_brownfields(*names):
    if not names:
        print "Please specify the names of projects you want to load."
        print "Did nothing..."
    for proj_name in names:
        project = get_project(proj_name)
        fips_list = project.fips_list
        if len(fips_list) > 1:
            fips_list = str(fips_list)
        elif len(fips_list) == 1:
            fips_list = "('{0}')".format(fips_list[0])
        else:
            raise "no fips_list specified"

        with db_connect() as conn:
            conn.execute("DROP TABLE IF EXISTS {local_brownfields_table}".format(local_brownfields_table=project.raw_brownfields_table))
            print '[{0}] Dropped local brownfield table'.format(proj_name)

            conn.execute("""
                CREATE TABLE {local_brownfields_table} AS
                    SELECT * FROM {global_brownfields_table}
                    LIMIT 0
                ;
            """.format(
                global_brownfields_table=settings.BROWNFIELDS_TABLE,
                local_brownfields_table=project.raw_brownfields_table,
            ))
            print '[{0}] Recreated local brownfield table'.format(proj_name)

            fips_query = """
                select FIPS from _G_counties where intersects(geom, (select collect(geom) from _G_counties where FIPS in {fips_list}))
            """.format(
                fips_list=fips_list
            )

            extended_fips_list = "(" + ",".join("'{0}'".format(row[0]) for row in conn.execute(fips_query).fetchall()) + ")"

            cur = None
            # while not cur or cur.rowcount > 0:
            query = """
                INSERT INTO {local_brownfields_table}
                SELECT * FROM {global_brownfields_table}
                where substr(FIPS_CODE, 1, 5) IN {extended_fips_list}
            """.format(
                global_brownfields_table=settings.BROWNFIELDS_TABLE,
                local_brownfields_table=project.raw_brownfields_table,
                buffer_radius=1609*10,
                extended_fips_list=extended_fips_list,
            )
            cur = conn.execute(query)
            print "rows added:", cur.rowcount
            conn.commit()

def task_generate_brownfields(*names):
    if not names:
        print "Please specify the names of projects you want to load."
        print "Did nothing..."
    for proj_name in names:
        project = get_project(proj_name)
        fips_list = project.fips_list
        if len(fips_list) > 1:
            fips_list = str(fips_list)
        elif len(fips_list) == 1:
            fips_list = "('{0}')".format(fips_list[0])
        else:
            raise "no fips_list specified"

        fips_subquery = """
            select FIPS from _G_counties 
            where intersects(
                geom, (
                    select collect(geom) 
                    from _G_counties where FIPS in {fips_list}
                )
            )
        """.format(fips_list=fips_list)

        with db_connect() as conn:
            extended_fips_list = "(" + ",".join("'{0}'".format(row[0]) for row in conn.execute(fips_subquery).fetchall()) + ")"

        # fips_subquery = re.sub(r"\(|\)", "", fips_list)
        output_path = project.app_data_dir('brownfields.geojson')
        try:
            os.remove(output_path)
        except OSError:
            pass
        sql = """SELECT * from brownfields where substr(FIPS_CODE, 1, 5) IN {extended_fips_list}""".format(extended_fips_list=extended_fips_list)
        print sql
        cmd = """ogr2ogr -f "GeoJSON" -sql "{sql}" -overwrite {output_path} {input_path}.shp""".format(
            input_path=os.path.join(settings.RAW_DATA_DIR, global_datasets['brownfields']['path']),
            output_path=output_path,
            sql=re.sub(r"\s+|\n+", " ", sql),
            # sql=sql,
        )
        call(cmd, shell=True)


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


def rebuild_demography_tables(*project_names):
    for proj_name in project_names:

        print '[{0}] Rebuilding demography table'.format(proj_name)

        project = get_project(proj_name)

        race_definitions = ",".join("{name} FLOAT".format(name=cat['name']) for cat in settings.demography_categories['race_categories'])
        occupation_definitions = ",".join("{name} FLOAT".format(name=cat['name']) for cat in settings.demography_categories['occupation_categories'])

        race_script = """
            BEGIN;
            DROP TABLE IF EXISTS {table};
            CREATE TABLE {table} (
                gid         INT PRIMARY KEY,
                {field_definitions}
            );
            END;
        """.format(
            table=project.race_table,
            field_definitions=race_definitions,
        )

        occupation_script = """
            BEGIN;
            DROP TABLE IF EXISTS {table};
            CREATE TABLE {table} (
                gid         INT PRIMARY KEY,
                {field_definitions}
            );
            END;
        """.format(
            table=project.occupation_table,
            field_definitions=occupation_definitions,
        )

        with db_connect() as conn:
            conn.executescript(race_script)
            conn.executescript(occupation_script)
            conn.commit()



def task_process_demography(*project_names):

    rebuild_demography_tables(*project_names)
    
    for proj_name in project_names:
        project = get_project(proj_name)

        for what in ('race', 'occupation'):
            if what == 'race':
                target_table = project.race_table
                buffer_mi = 1.0
            elif what == 'occupation':
                target_table = project.occupation_table
                buffer_mi = 5.0
            category_key = what + '_categories'
            categories = settings.demography_categories[category_key]
            rawname_list = ",".join(cat['rawname'] for cat in categories)
            name_list = ",".join(cat['name'] for cat in categories)
            assignment_list = ",".join(
                ("SUM( density * {rawname} ) AS {name}".format(rawname=cat['rawname'], name=cat['name']) for cat in categories)
            )

           
            with db_connect() as conn:
                print 'processing ', proj_name, ':', what

                cur = None
                limit = settings.BACKEND_CHUNK_SIZE
                offset = 0
                while not cur or cur.rowcount > 0:
                    query = """
                        INSERT INTO {target_table} (gid, {name_list}) 
                        SELECT
                            {pk},
                            {assignment_list}
                        FROM (
                            SELECT 
                                raw.{pk},
                                census.*,
                                ST_Area( ST_Intersection( circle_buffer, census.tract ) ) / census.tract_area AS density
                            FROM (
                                SELECT
                                    {pk},
                                    ST_Buffer( ST_Transform( ST_Centroid(geom), {equal_area_srid} ), 1609*{buffer_mi} ) as circle_buffer
                                FROM {raw_industrial_table}
                                LIMIT {limit} OFFSET {offset}
                            ) as raw
                             JOIN (
                                SELECT 
                                    {rawname_list},
                                    geom as tract,
                                    ST_Area( geom ) as tract_area
                                FROM {local_demography_table}
                            ) as census
                            ON ST_Intersects( raw.circle_buffer, census.tract )
                        )
                        GROUP BY {pk};
                    """.format(
                        pk=settings.SPATIALITE_PK_NAME,
                        target_table=target_table,
                        local_demography_table=project.raw_demography_table,
                        raw_industrial_table=project.raw_industrial_table,
                        equal_area_srid=settings.EQUAL_AREA_SRID,
                        name_list=name_list,
                        rawname_list=rawname_list,
                        assignment_list=assignment_list,
                        buffer_mi=buffer_mi,
                        limit=limit,
                        offset=offset,
                    )
                    cur = conn.execute(query)
                    print offset, '... '
                    offset += limit
                    conn.commit()


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


def task_generate_converted(*project_names):

    set_name = 'converted'
    
    with db_connect() as conn:
        for proj_name in project_names:
            project = get_project(proj_name)

            query_template = """
                SELECT *, AsText(geom) as geom_wkt from {table}
            """

            query = query_template.format(
                table=project.raw_converted_table,
                chunk_size=settings.FEATURE_CHUNK_SIZE,
            )

            cur = conn.execute(query)
            chunk_num = 0
            chunk = cur.fetchmany(settings.FEATURE_CHUNK_SIZE)

            json_dir = project.app_data_dir('json')
            lazy_mkdir(json_dir)

            for f in os.listdir(json_dir):
                if f.startswith(set_name+'-') and f.endswith('.geojson'):
                    # print f
                    os.remove(os.path.join(json_dir, f))

            while chunk:

                with open(os.path.join(json_dir, set_name+'-{0}.geojson'.format(chunk_num)), 'w') as f:

                    features = []

                    for row in chunk:
                        properties = {}
                        for key in row.keys():
                            k = key.lower()
                            if k not in ('geom', 'geom_wkt'):
                                properties[k] = row[key]

                        geometry = wkt.loads(row['geom_wkt'])
                        geometry = geojson.loads(geojson.dumps(geometry))

                        features.append({
                            'type': 'Feature',
                            'geometry': geometry,
                            'properties': properties,
                        })

                    f.write(json.dumps({
                        'type': 'FeatureCollection',
                        'features': features,
                    }))

                chunk = cur.fetchmany(settings.FEATURE_CHUNK_SIZE)
                chunk_num += 1



def task_generate_industrial(*project_names):

    create_industrial_table(*project_names)
    setup_project_directories()
    
    with db_connect() as conn:
        for proj_name in project_names:
            project = get_project(proj_name)

            probability_names = [p['name'] for p in project.industrial_parcels['probability_categories']]
            race_names = [r['name'] for r in project.demography['race_categories']]
            occupation_names = [o['name'] for o in project.demography['occupation_categories']]

            query_template = """
                SELECT *, AsText(CastToMultiPolygon(geom)) as geom_wkt from {industrial} i
            """
            if settings.USE_DEMOGRAPHY:
                query_template += " LEFT JOIN {race} r ON r.gid = i.gid LEFT JOIN {occupation} o ON o.gid = i.gid "

            query_template += " ORDER BY size_metric DESC "

            query = query_template.format(
                # pk=settings.SPATIALITE_PK_NAME,
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

                    industrial_features = []

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

def task_generate_naics(*project_names):
    # Generate industry employment data from 3 files
    # countywide and nationwide data are per-NAICS
    # statewide data is only the total across ALL NAICS codes
    YEAR_START = 1990
    NAICS_COLUMN = 'industry_code'
    FIPS_COLUMN = 'area_fips'
    FIRST_YEAR_COLUMN = 'fyear'
    NA_VALUE = 'NA'

    for proj_name in project_names:
        project = get_project(proj_name)

        def parseCSV(name, path):
            data = {}
            columns = {}
            years = []
            is_statewide = name == 'statewide'
            with open(path, 'rU') as csvfile:
                reader = csv.reader(csvfile, delimiter=',', quotechar='"')
                head = reader.next()

                # get indices of columns
                for i, v in enumerate(head):
                    columns[v] = i
                
                # get consecutive years
                for y in xrange(YEAR_START, sys.maxint):
                    if str(y) in columns:
                        years.append(y)
                    else:
                        break

                for row in reader:

                    def get(column_name):
                        return row[columns[column_name]]

                    if is_statewide:
                        use_row = project.fips_list[0][0:2] == get(FIPS_COLUMN)[0:2]
                    elif name == 'nationwide':
                        use_row = True
                    else:
                        use_row = get(FIPS_COLUMN) in project.fips_list

                    if use_row:

                        code = get(NAICS_COLUMN).strip()
                        base_year = get(FIRST_YEAR_COLUMN)
                        first_nonnull_year = None
                        if is_statewide or len(code) == 4:
                            values = []
                            for year in years:
                                value = get(str(year))
                                if value != NA_VALUE:
                                    value = float(value)
                                    if first_nonnull_year is None:
                                        first_nonnull_year = int(year)
                                else:
                                    value = None
                                values.append(value)
                            if first_nonnull_year is not None:
                                assert(first_nonnull_year == int(base_year))  # sanity
                                base_year_value = float(get(base_year))
                                emp_growth = []
                                for year, value in zip(years, values):
                                    ratio = None if value is None else value / base_year_value 
                                    emp_growth.append({'year': year, 'value': ratio})
                                data[code] = {
                                    'base_year': base_year,
                                    'emp_initial': base_year_value,
                                    'emp_growth': emp_growth,
                                }
            return data


        data = {}

        for name, path in settings.naics_csv.items():
            data[name] = parseCSV(name, os.path.join(settings.RAW_DATA_DIR, path))

        with open(os.path.join(project.app_data_dir(), 'naics-trends.json'), 'w') as f:
            print 'writing NAICS data to', f
            f.write(json.dumps({'naics_trends': data}))

def setup_project_directories():
    lazy_mkdir(settings.APP_DATA_DIR)  # main project dir

    for project in projects:
        lazy_mkdir(project.app_data_dir())


def task_build():
    '''
    Do everything!
    '''
    setup_project_directories()


def task_kokoromi(*project_names):
     for proj_name in project_names:
        project = get_project(proj_name)
        with db_connect() as conn:
            query_transform = """select AsText( Transform( Centroid( GUnion( Centroid(
                ( select geom from {table} limit 100 )
            )) ), {srid} ) ) from {table}"""
            query_plain = """select AsText( Centroid( GUnion( Centroid(
                (select geom from {table} limit 100)
            )) ) ) from {table}"""

            q1 = query_transform.format(
                table=project.raw_demography_table,
                srid=2163,
            )

            q2 = query_transform.format(
                table=project.raw_industrial_table,
                srid=2163,
            )

            print conn.execute(q1).fetchall()
            print conn.execute(q2).fetchone()


def main():

    tasks = {
        # 'build': task_build,
        'load': task_load_project_shapefiles,
        'load-global': task_load_global_shapefiles,
        'load-all': task_load_all,
        'localize-demography': task_localize_demography,
        'localize-brownfields': task_localize_brownfields,
        'process-demography': task_process_demography,
        'generate-brownfields': task_generate_brownfields,
        'generate-industrial': task_generate_industrial,
        'generate-converted': task_generate_converted,
        'generate-naics': task_generate_naics,
        'kokoromi': task_kokoromi,
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
