import os
from conf import settings

def lazy_mkdir(path):
    try:
        os.mkdir(path)
    except OSError:
        pass

def global_raw_data_dir(path):
    return os.path.join(settings.RAW_DATA_DIR, path)

def load_shapefile(name, path, prefix=''):
    line = ".loadshp {shp} {name} {encoding} {srid} {geom_column_name}".format(
        name=prefix + name,
        shp=global_raw_data_dir(path),
        encoding=settings.SPATIALITE_ENCODING,
        srid=settings.SPATIALITE_SRID,
        geom_column_name=settings.SPATIALITE_GEOMETRY_COLUMN_NAME,
    )
    ret = os.system("echo \"{line}\" | spatialite {file}".format(
        line=line,
        file=settings.SPATIALITE_DB_FILE,
    ))