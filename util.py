import os
from conf import settings


def lazy_mkdir(path):
    try:
        os.mkdir(path)
    except OSError:
        pass

def global_raw_data_dir(path):
    return os.path.join(settings.RAW_DATA_DIR, path)


def execute_sql_command(sql):
    code = os.system("echo \"{sql}\" | spatialite {file}".format(sql=sql, file=settings.SPATIALITE_DB_FILE))
    if code > 0:
        raise Exception("SQL Error")


def load_shapefile(name, path, srid, prefix=''):
    table = prefix + name
    line = ".loadshp {shp} {table} {encoding} {srid} {geom_column_name} {pk_name} MULTIPOLYGON 2d 0 1".format(
        table=table,
        shp=global_raw_data_dir(path),
        encoding=settings.SPATIALITE_ENCODING,
        srid=srid,
        geom_column_name=settings.SPATIALITE_GEOMETRY_COLUMN_NAME,
        pk_name=settings.SPATIALITE_PK_NAME,
    )
    execute_sql_command("DROP TABLE IF EXISTS {table};".format(table=table))
    execute_sql_command(line)
    # execute_sql_command("SELECT CreateSpatialIndex('{table}', '{geom_column_name}');".format(
    #     table=table,
    #     geom_column_name=settings.SPATIALITE_GEOMETRY_COLUMN_NAME,
    # ))



# def db_connect():
#     from sqlalchemy import create_engine
#     engine = create_engine('sqlite://%s' % (settings.SPATIALITE_DB_FILE,))
#     conn = engine.connect()
#     return engine
