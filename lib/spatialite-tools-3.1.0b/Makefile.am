ACLOCAL_AMFLAGS = -I m4

bin_PROGRAMS = spatialite \
	spatialite_tool \
	spatialite_network \
	shp_doctor \
	exif_loader \
	spatialite_osm_net \
	spatialite_osm_map \
	spatialite_osm_raw \
	spatialite_osm_filter \
	spatialite_gml

INCLUDES = @CFLAGS@
INCLUDES += -I$(top_srcdir)

spatialite_SOURCES = shell.c
spatialite_tool_SOURCES = spatialite_tool.c
spatialite_network_SOURCES = spatialite_network.c
shp_doctor_SOURCES = shp_doctor.c
exif_loader_SOURCES = exif_loader.c
spatialite_osm_net_SOURCES = spatialite_osm_net.c
spatialite_osm_map_SOURCES = spatialite_osm_map.c
spatialite_osm_raw_SOURCES = spatialite_osm_raw.c
spatialite_osm_filter_SOURCES = spatialite_osm_filter.c
spatialite_gml_SOURCES = spatialite_gml.c

spatialite_osm_map_LDADD = @LIBSPATIALITE_LIBS@ \
	@LIBFREEXL_LIBS@ @LIBREADOSM_LIBS@ 
spatialite_osm_raw_LDADD = @LIBSPATIALITE_LIBS@ \
	@LIBFREEXL_LIBS@ @LIBREADOSM_LIBS@
spatialite_osm_net_LDADD = @LIBSPATIALITE_LIBS@ \
	@LIBFREEXL_LIBS@ @LIBREADOSM_LIBS@
spatialite_gml_LDADD = @LIBSPATIALITE_LIBS@ \
	@LIBFREEXL_LIBS@ \
	-lexpat 
spatialite_LDADD = @LIBSPATIALITE_LIBS@ \
	@LIBFREEXL_LIBS@ \
	@READLINE_LIBS@
LDADD = @LIBSPATIALITE_LIBS@ \
	@LIBFREEXL_LIBS@

EXTRA_DIST = makefile.vc nmake.opt \
	Makefile-static-MinGW \
	Makefile-static-Linux \
	Makefile-static-MacOsX

AUTOMAKE_OPTIONS = dist-zip

