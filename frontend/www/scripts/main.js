(function() {
  var Colormap, ConvertedPolygon, Feature, Feature2D, IndustrialPolygon, MultiPolygonCollection, Polygon, StackedBarChart, i, line, lines, noDataColor, orange_red, parseLine, races7, raw, red_yellow_green, rgbs, slugs, swatch, yellow_green_blue,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  window.HTTP = {
    base: '',
    status: {},
    showLoading: function() {},
    hideLoading: function() {},
    setup: function() {
      return $.ajaxSetup({
        dataType: 'json',
        cache: true,
        beforeSend: function(xhr, settings) {
          return xhr.setRequestHeader("Cache-Control", "max-age=3600");
        }
      });
    },
    call: function(type, uri, data) {
      var ret,
        _this = this;
      console.debug('making API call: ' + this.base + uri);
      this.status[uri] = 'waiting';
      ret = $.ajax(this.base + uri, {
        data: data,
        type: type,
        success: function(d) {
          var allOK, state, _ref;
          console.debug('SUCCESS: ' + _this.base + uri);
          _this.status[uri] = 'success';
          allOK = true;
          _ref = _this.status;
          for (uri in _ref) {
            state = _ref[uri];
            if (state !== 'success') {
              allOK = false;
            }
          }
          if (allOK) {
            return _this.hideLoading();
          }
        },
        error: function() {
          console.error("HTTP error");
          return _this.status[uri] = 'error';
        }
      });
      this.showLoading();
      return ret;
    },
    blocking: function(type, uri, data) {
      var ret;
      console.debug('making API call: ' + this.base + uri);
      this.status[uri] = 'waiting';
      ret = $.ajax(this.base + uri, {
        data: data,
        type: type,
        async: false
      });
      this.showLoading();
      return ret;
    },
    get: function(uri, data) {
      return this.call('get', uri, data);
    },
    post: function(uri, data) {
      return this.call('post', uri, data);
    }
  };

  window.Settings = {
    histogramMaxValue: 0.5,
    initialColorBins: 5,
    fillOpacity: 0.9,
    activeColor: '#4c4',
    noDataColor: '#666',
    debugLimit: 500,
    minSizeMetric: 5,
    baseMinZoom: 10,
    rasterMaxZoom: 13,
    brownfieldSmallZoom: 12,
    graphWidth: 180,
    barGraphWidth: 50,
    lineGraphHeight: 125,
    graphs: {
      trends: {
        colors: [[251, 128, 114], [100, 222, 60], [10, 10, 10]]
      }
    },
    panOnActivate: true,
    useLocalData: false,
    useDemography: true,
    requireDemography: true,
    switchLatLng: true,
    baseStyle: function() {
      return {
        weight: 1,
        color: '#333',
        opacity: 0.5
      };
    },
    activeStyle: function() {
      return {
        fillOpacity: 1.0,
        fillColor: this.activeColor,
        weight: 3,
        opacity: 1.0
      };
    },
    hoverStyle: function() {
      return {
        fillOpacity: 1.0,
        weight: 2,
        opacity: 1.0
      };
    },
    colors: {
      race: ['rgb(255, 255, 179)', 'rgb(141, 211, 199)', 'rgb(190, 186, 218)', 'rgb(251, 128, 114)', 'rgb(128, 177, 211)', 'rgb(253, 180, 98)', 'rgb(179, 222, 105)'],
      occupation: ['rgb(255, 255, 179)', 'rgb(141, 211, 199)', 'rgb(190, 186, 218)', 'rgb(251, 128, 114)', 'rgb(128, 177, 211)', 'rgb(253, 180, 98)', 'rgb(179, 222, 105)']
    }
  };

  Settings.convertedColors = {
    'SFR': 'rgb(0, 200, 0)',
    'MFR': 'rgb(0, 100, 0)',
    'COM': 'rgb(255, 0, 0)',
    'OFF': 'rgb(0, 0, 200)',
    'OTH': 'rgb(200, 0, 200)',
    'NON': Settings.noDataColor
  };

  Settings.convertedCategories = {
    'SFR': 'Single Family Residential',
    'MFR': 'Multi Family Residential',
    'COM': 'Commercial',
    'OFF': 'Office',
    'OTH': 'Other',
    'NON': 'No Data'
  };

  window.lerp = function(a, b, f) {
    return a + f * (b - a);
  };

  window.lerpColor = function(a, b, f) {
    return [lerp(a[0], b[0], f), lerp(a[1], b[1], f), lerp(a[2], b[2], f)];
  };

  window.makeColorString = function(rgb) {
    var b, g, r;
    r = rgb[0], g = rgb[1], b = rgb[2];
    return "rgb(" + r + "," + g + "," + b + ")";
  };

  red_yellow_green = '252, 141, 89; 255, 255, 191; 153, 213, 148; \n215, 25, 28; 253, 174, 97; 171, 221, 164; 43, 131, 186; \n215, 25, 28; 253, 174, 97; 255, 255, 191; 171, 221, 164; 43, 131, 186; \n213, 62, 79; 252, 141, 89; 254, 224, 139; 230, 245, 152; 153, 213, 148; 50, 136, 189; ';

  orange_red = '254, 232, 200; 253, 187, 132; 227, 74, 51; \n254, 240, 217; 253, 204, 138; 252, 141, 89; 215, 48, 31; \n254, 240, 217; 253, 204, 138; 252, 141, 89; 227, 74, 51; 179, 0, 0; \n254, 240, 217; 253, 212, 158; 253, 187, 132; 252, 141, 89; 227, 74, 51; 179, 0, 0; ';

  yellow_green_blue = '237, 248, 177; 127, 205, 187; 44, 127, 184; \n255, 255, 204; 161, 218, 180; 65, 182, 196; 34, 94, 168; \n255, 255, 204; 161, 218, 180; 65, 182, 196; 44, 127, 184; 37, 52, 148; \n255, 255, 204; 199, 233, 180; 127, 205, 187; 65, 182, 196; 44, 127, 184; 37, 52, 148; ';

  parseLine = function(line) {
    return line.split(";").map($.trim).filter(function(c) {
      return c.length > 0;
    }).map(function(c) {
      return c.split(", ");
    });
  };

  window.swatches = (function() {
    var _i, _j, _len, _len1, _ref, _results;
    _ref = [orange_red, yellow_green_blue, red_yellow_green];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      raw = _ref[_i];
      lines = (function() {
        var _j, _len1, _ref1, _results1;
        _ref1 = raw.split("\n");
        _results1 = [];
        for (i = _j = 0, _len1 = _ref1.length; _j < _len1; i = ++_j) {
          line = _ref1[i];
          _results1.push(parseLine(line));
        }
        return _results1;
      })();
      swatch = {};
      for (_j = 0, _len1 = lines.length; _j < _len1; _j++) {
        rgbs = lines[_j];
        swatch[rgbs.length] = rgbs;
      }
      _results.push(swatch);
    }
    return _results;
  })();

  noDataColor = window.Settings.noDataColor;

  races7 = '255, 255, 179; 141, 211, 199; 190, 186, 218; 251, 128, 114; 128, 177, 211; 253, 180, 98; 179, 222, 105;';

  window.raceColors = parseLine(races7);

  StackedBarChart = (function() {
    StackedBarChart.prototype.color = null;

    StackedBarChart.prototype.svg = null;

    StackedBarChart.prototype.$container = null;

    StackedBarChart.prototype.opts = {};

    function StackedBarChart(opts) {
      this.opts = opts;
      this.legendData = this.opts.legendData;
      this.name = this.opts.name;
      this.id = "" + this.name + "-pie";
    }

    StackedBarChart.prototype.initialize = function() {
      var height, key, legend, li, slice, width, _ref, _ref1;
      width = this.opts.width;
      height = this.opts.height || this.opts.width;
      this.$container = $("#" + this.id);
      this.svg = d3.select("#" + this.id + " .graph").append("svg:svg").attr("width", width).attr("height", height).append("svg:g");
      this.layout = function(data) {
        var d, obj, out, prev, sum, val;
        sum = data.map(function(d) {
          return d.population;
        }).reduce(function(a, b) {
          return a + b;
        });
        prev = 0;
        out = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = data.length; _i < _len; _i++) {
            d = data[_i];
            val = height * d.population / sum;
            obj = {
              width: width,
              height: val,
              y: +prev,
              data: d
            };
            prev += val;
            _results.push(obj);
          }
          return _results;
        })();
        return out;
      };
      i = 0;
      _ref = this.legendData;
      for (key in _ref) {
        slice = _ref[key];
        this.legendData[key].color = Settings.colors.race[i++];
      }
      legend = this.$container.find('ul.legend');
      _ref1 = this.legendData;
      for (key in _ref1) {
        slice = _ref1[key];
        li = $("<li class=\"" + key + "\">\n	<div class=\"color\" style=\"background: " + slice.color + "\"></div>&nbsp;<div class=\"label\">" + slice.label + "</div>\n</li>");
        legend.append(li);
      }
      return this.$container.append('<br class="clear"/>');
    };

    StackedBarChart.prototype.setFeature = function(f) {
      var k, v, values;
      values = (function() {
        var _ref, _results;
        _ref = f.properties.demography[this.name];
        _results = [];
        for (k in _ref) {
          v = _ref[k];
          if (v === 0) {
            this.$container.find("li." + k).fadeOut();
          } else {
            this.$container.find("li." + k).fadeIn();
          }
          _results.push({
            name: k,
            population: v
          });
        }
        return _results;
      }).call(this);
      this.setData(values);
      return this.$container.fadeIn();
    };

    StackedBarChart.prototype.hide = function() {
      return this.$container.fadeOut();
    };

    StackedBarChart.prototype.setData = function(values) {
      var data, rects, slice,
        _this = this;
      data = this.layout(values);
      slice = this.svg.selectAll("g.slice").data(data, function(d) {
        return d.data.name;
      });
      slice.transition().duration(777).select('rect').attr("y", function(d) {
        return d.y;
      }).attr("height", function(d) {
        return d.height;
      });
      return rects = slice.enter().append("svg:g").attr("class", "slice").append("svg:rect").attr("fill", function(d) {
        return _this.legendData[d.data.name].color;
      }).attr("width", function(d) {
        return d.width;
      }).attr("y", function(d) {
        return d.y;
      }).attr("height", function(d) {
        return d.height;
      }).each(function(d) {
        return this._current = d;
      });
    };

    return StackedBarChart;

  })();

  window.StackedBarChart = StackedBarChart;

  Colormap = (function() {
    Colormap.loaded = [];

    Colormap.currentIndex = null;

    Colormap.currentNumLevels = Settings.initialColorBins;

    Colormap.currentSegmentation = 'linear';

    Colormap.prototype.levels = [];

    Colormap.prototype.colorLo = null;

    Colormap.prototype.colorHi = null;

    Colormap.prototype.valLo = null;

    Colormap.prototype.valHi = null;

    Colormap.makeV2 = function(swatch, riskRange) {
      var N, levels, r, rgb, thresh, valHi, valLo;
      N = swatch.length;
      valLo = riskRange[0], valHi = riskRange[1];
      levels = (function() {
        var _i, _len, _results;
        _results = [];
        for (i = _i = 0, _len = swatch.length; _i < _len; i = ++_i) {
          rgb = swatch[i];
          r = parseFloat(i) / N;
          thresh = lerp(valLo, valHi, r);
          _results.push([thresh, rgb]);
        }
        return _results;
      })();
      return new Colormap(levels.reverse(), valLo, valHi);
    };

    Colormap.makeV3 = function(swatch, segmentation) {
      var N, f, levels, q, r, rgb, risks, thresh, total, valHi, valLo, _ref, _ref1;
      N = swatch.length;
      if (segmentation === 'quantile') {
        risks = ((function() {
          var _ref, _results;
          _ref = ILC.industrial.items;
          _results = [];
          for (i in _ref) {
            f = _ref[i];
            if (f.risk() != null) {
              _results.push(f.risk());
            }
          }
          return _results;
        })()).sort();
        _ref = [risks[0], risks[risks.length - 1]], valLo = _ref[0], valHi = _ref[1];
        total = risks.length;
        levels = (function() {
          var _i, _len, _results;
          _results = [];
          for (i = _i = 0, _len = swatch.length; _i < _len; i = ++_i) {
            rgb = swatch[i];
            q = parseInt(total * i / N);
            thresh = risks[q];
            _results.push([thresh, rgb]);
          }
          return _results;
        })();
      } else {
        _ref1 = ILC.getRiskRange(), valLo = _ref1[0], valHi = _ref1[1];
        levels = (function() {
          var _i, _len, _results;
          _results = [];
          for (i = _i = 0, _len = swatch.length; _i < _len; i = ++_i) {
            rgb = swatch[i];
            r = parseFloat(i) / N;
            thresh = lerp(valLo, valHi, r);
            _results.push([thresh, rgb]);
          }
          return _results;
        })();
      }
      return new Colormap(levels.reverse(), valLo, valHi);
    };

    Colormap.updatePreviews = function(N, segmentation) {
      var $el, cmap, _i, _len, _ref;
      if (N == null) {
        N = Colormap.currentNumLevels;
      }
      if (segmentation == null) {
        segmentation = Colormap.currentSegmentation;
      } else {
        Colormap.currentSegmentation = segmentation;
      }
      this.loaded = (function() {
        var _i, _len, _ref, _results;
        _ref = window.swatches;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          swatch = _ref[_i];
          _results.push(this.makeV3(swatch[N], segmentation));
        }
        return _results;
      }).call(this);
      $el = $('#colormap-picker .colormaps');
      $el.html('');
      _ref = this.loaded;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        cmap = _ref[i];
        $el.append(cmap.previewHTML(i));
      }
      $('#colormap-picker .colormap-preview[data-id=' + this.currentIndex + ']').addClass('current');
      return Colormap.currentNumLevels = N;
    };

    Colormap.setCurrent = function(i) {
      this.currentIndex = i;
      $('#colormap-picker .colormap-preview').removeClass('current');
      return $('#colormap-picker .colormap-preview[data-id=' + i + ']').addClass('current');
    };

    function Colormap(levels, valLo, valHi) {
      this.levels = levels;
      this.valLo = valLo;
      this.valHi = valHi;
    }

    Colormap.prototype.getColor = function(val) {
      var lvl, rgb, thresh, _i, _len, _ref;
      if (val == null) {
        return Settings.noDataColor;
      }
      _ref = this.levels;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        lvl = _ref[_i];
        thresh = lvl[0], rgb = lvl[1];
        if (val >= thresh) {
          return rgb;
        }
      }
      return this.levels[this.levels.length - 1][1];
    };

    Colormap.prototype.getColorString = function(val) {
      var b, g, r, _ref;
      _ref = this.getColor(val), r = _ref[0], g = _ref[1], b = _ref[2];
      return "rgb(" + r + "," + g + "," + b + ")";
    };

    Colormap.prototype.legendHTML = function() {
      var $div, b, colorString, g, lastThresh, li, lis, lvl, precision, r, rgb, text, thresh, _i, _j, _len, _len1, _ref, _ref1;
      precision = 4;
      lastThresh = (this.valHi * 100).toFixed(0);
      $div = $('<ul class="legend colormap-legend"></ul>');
      lis = [];
      _ref = this.levels;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        lvl = _ref[_i];
        thresh = lvl[0], rgb = lvl[1];
        r = rgb[0], g = rgb[1], b = rgb[2];
        colorString = "rgb(" + r + "," + g + "," + b + ")";
        thresh = (thresh * 100).toFixed(0);
        text = lastThresh != null ? "" + thresh + "% - " + lastThresh + "%" : "" + thresh + "+";
        lis.push("<li>\n	<div class=\"color\" style=\"background: " + colorString + "\"></div>\n	<div class=\"label\">" + text + "</div>\n</li>");
        lastThresh = thresh;
      }
      _ref1 = lis.reverse();
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        li = _ref1[_j];
        $div.append(li);
      }
      $div.append("<li>\n	<div class=\"color no-fill\" style=\"border: 3px solid " + Settings.noDataColor + "; background: rgba(40, 40, 40, 0.05);\"></div>\n	<div class=\"label\">No Data</div>\n</li>");
      return $div;
    };

    Colormap.prototype.previewHTML = function(id) {
      var $div, b, colorString, g, lastThresh, li, lis, lvl, precision, r, rgb, thresh, _i, _j, _len, _len1, _ref, _ref1;
      precision = 3;
      lastThresh = null;
      $div = $("<ul class=\"colormap-preview\" data-id=\"" + id + "\"></ul>");
      lis = [];
      _ref = this.levels;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        lvl = _ref[_i];
        thresh = lvl[0], rgb = lvl[1];
        r = rgb[0], g = rgb[1], b = rgb[2];
        colorString = "rgb(" + r + "," + g + "," + b + ")";
        lis.push("<li>\n	<div class=\"color\" style=\"background: " + colorString + "\"></div>\n</li>");
      }
      _ref1 = lis.reverse();
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        li = _ref1[_j];
        $div.append(li);
      }
      return $div;
    };

    return Colormap;

  })();

  window.Colormap = Colormap;

  Polygon = (function() {
    Polygon.prototype.id = null;

    Polygon.prototype.L = null;

    Polygon._holesWarning = false;

    function Polygon(coords) {
      if (typeof coords[0][0] === 'object') {
        if (!Polygon._holesWarning) {
          console.warn("cannot use polygon with holes, using exterior ring only.");
          Polygon._holesWarning = true;
        }
        coords = coords[0];
      }
      this.coords = coords.slice(0);
      this.L = new L.Polygon(coords);
    }

    Polygon.prototype.centroid = function() {
      var len, ret, sum;
      len = this.coords.length;
      sum = this.coords.reduce(function(a, b) {
        return [a[0] + b[0], a[1] + b[1]];
      });
      ret = sum.map(function(x) {
        return x / len;
      });
      return ret;
    };

    return Polygon;

  })();

  window.Polygon = Polygon;

  Feature = (function() {
    function Feature() {}

    Feature.gid = null;

    return Feature;

  })();

  window.Feature = Feature;

  Feature2D = (function(_super) {
    __extends(Feature2D, _super);

    function Feature2D(coordinates) {
      Feature2D.__super__.constructor.call(this);
      if (Settings.switchLatLng) {
        coordinates = coordinates.map(function(polygons) {
          return polygons.map(function(points) {
            var p;
            if (typeof points[0] === 'object') {
              return points = (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = points.length; _i < _len; _i++) {
                  p = points[_i];
                  _results.push([p[1], p[0]]);
                }
                return _results;
              })();
            } else {
              return points = [points[1], points[0]];
            }
          });
        });
      }
      this.components = coordinates.map(function(p) {
        return new Polygon(p);
      });
      this.L = new L.MultiPolygon(coordinates.slice(0), Settings.baseStyle());
    }

    Feature2D.prototype.centroid = function() {
      var len;
      len = this.components.length;
      return this.components.map(function(poly) {
        return poly.centroid();
      }).reduce(function(a, b) {
        return [a[0] + b[0], a[1] + b[1]];
      }).map(function(x) {
        return x / len;
      });
    };

    return Feature2D;

  })(Feature);

  window.Feature2D = Feature2D;

  IndustrialPolygon = (function(_super) {
    __extends(IndustrialPolygon, _super);

    IndustrialPolygon.prototype.L = null;

    IndustrialPolygon.prototype.baseColor = null;

    IndustrialPolygon.prototype.components = null;

    IndustrialPolygon.activeFeature = null;

    IndustrialPolygon.infoPopup = new L.Popup({
      offset: L.point(0, -4)
    });

    IndustrialPolygon.riskType = 'risk_main';

    IndustrialPolygon.setActive = function(f, dom_event) {
      var pos;
      this.clearActive(dom_event);
      this.activeFeature = f;
      f.L.setStyle(Settings.activeStyle());
      ILC.graphs.demography.race.setFeature(f);
      ILC.graphs.demography.occupation.setFeature(f);
      ILC.graphs.naics_trends.setNAICS(f.naics);
      $('#legends-and-colormaps').fadeOut();
      if (Settings.panOnActivate) {
        pos = f.centroid();
        return ILC.map.panTo(pos);
      }
    };

    IndustrialPolygon.clearActive = function(dom_event) {
      if (this.activeFeature != null) {
        this.activeFeature.L.setStyle(Settings.baseStyle());
        this.activeFeature.updateColor(ILC.colormap());
        return this.activeFeature = null;
      }
    };

    IndustrialPolygon.prototype.risk = function() {
      var val;
      if (this.risk_main == null) {
        throw "risk_main not set";
      }
      val = (function() {
        switch (IndustrialPolygon.riskType) {
          case 'risk_main':
            return this.risk_main;
          case 'risk_res':
            return this.risk_res;
          case 'risk_com':
            return this.risk_com;
          default:
            throw "unknown risk type: " + IndustrialPolygon.riskType;
        }
      }).call(this);
      if (val === 0) {
        return null;
      } else {
        return val;
      }
    };

    IndustrialPolygon.prototype.updateColor = function(colormap) {
      if (this.risk() == null) {
        return this.L.setStyle({
          color: Settings.noDataColor,
          fillColor: Settings.noDataColor,
          fillOpacity: 0.05,
          opacity: 1,
          weight: 1.5
        });
      } else {
        if (colormap) {
          this.baseColor = colormap.getColorString(this.risk());
          return this.L.setStyle({
            fillColor: this.baseColor,
            fillOpacity: Settings.fillOpacity
          });
        }
      }
    };

    function IndustrialPolygon(data) {
      var coords, geom, name, occupation, occupation_total, props, race, raceResidual, raceThreshold, race_total, v,
        _this = this;
      props = data.properties;
      geom = data.geometry;
      this.gid = props.gid;
      this.risk_main = props.probability.risk_main;
      this.risk_res = props.probability.risk_res;
      this.risk_com = props.probability.risk_com;
      this.size_metric = props.size_metric;
      this.naics3 = props.naics.toString().substr(0, 3);
      this.naics4 = props.naics.toString().substr(0, 4);
      this.naics = this.naics4;
      this.properties = data.properties;
      coords = geom.coordinates;
      IndustrialPolygon.__super__.constructor.call(this, coords);
      this.L.obj = this;
      if (Settings.useDemography) {
        race = props.demography.race;
        occupation = props.demography.occupation;
        race_total = ((function() {
          var _results;
          _results = [];
          for (i in race) {
            v = race[i];
            _results.push(v);
          }
          return _results;
        })()).reduce(function(a, b) {
          return a + b;
        });
        occupation_total = ((function() {
          var _results;
          _results = [];
          for (i in occupation) {
            v = occupation[i];
            _results.push(v);
          }
          return _results;
        })()).reduce(function(a, b) {
          return a + b;
        });
        raceResidual = 0.0;
        raceThreshold = 0.02;
        if (!(__indexOf.call(race, 'other') >= 0)) {
          race['other'] = 0.0;
        }
        for (name in race) {
          v = race[name];
          race[name] = v / race_total;
        }
        for (name in race) {
          v = race[name];
          if (v < raceThreshold) {
            raceResidual += v;
            race[name] = 0;
          }
        }
        if (raceResidual > 0) {
          race['other'] += raceResidual;
        }
        for (name in occupation) {
          v = occupation[name];
          occupation[name] = v / occupation_total;
        }
      } else {
        race = {};
        occupation = {};
      }
      props.demography.race = race;
      props.demography.occupation = occupation;
      this.L.on('click', function(e) {
        return IndustrialPolygon.setActive(_this, e.originalEvent);
      }).on('mouseover', function(e) {
        return IndustrialPolygon.infoPopup.setLatLng(e.latlng).openOn(ILC.map);
      }).on('mousemove', function(e) {
        var content;
        if ((IndustrialPolygon.activeFeature == null) || IndustrialPolygon.activeFeature.L !== e.target) {
          e.target.setStyle(Settings.hoverStyle());
        }
        if ((_this.naics != null) && _this.naics > 0) {
          content = _this.naics + " - " + ILC.naics_list[_this.naics];
        } else {
          content = "<i>Industry unknown</i>";
        }
        IndustrialPolygon.infoPopup.setLatLng(e.latlng).setContent(content);
        return $('#debug-stats.on').show().html("<p>pxSizeEstimate: " + _this.pxSizeEstimate + "</p>");
      }).on('mouseout', function(e) {
        ILC.map.closePopup();
        if ((IndustrialPolygon.activeFeature == null) || IndustrialPolygon.activeFeature.L !== e.target) {
          e.target.setStyle(Settings.baseStyle());
          e.target.obj.updateColor();
        }
        return $('#debug-stats.on').hide();
      });
    }

    return IndustrialPolygon;

  })(Feature2D);

  window.IndustrialPolygon = IndustrialPolygon;

  ConvertedPolygon = (function(_super) {
    __extends(ConvertedPolygon, _super);

    function ConvertedPolygon(data) {
      ConvertedPolygon.__super__.constructor.call(this, data.geometry.coordinates);
      this.convertedTo = (function() {
        switch (data.properties.twlsm.trim().toUpperCase()) {
          case 'R':
            return '';
        }
      })();
      this.L.setStyle({
        fillOpacity: 0,
        weight: 3,
        color: Settings.convertedColors[data.converted_to] || Settings.convertedColors['NON'],
        fillColor: null,
        clickable: false
      });
    }

    return ConvertedPolygon;

  })(Feature2D);

  window.ConvertedPolygon = ConvertedPolygon;

  MultiPolygonCollection = (function() {
    function MultiPolygonCollection(polygonClass, features) {
      this.polygonClass = polygonClass;
      this.items = {};
      this.L = new L.FeatureGroup();
    }

    MultiPolygonCollection.prototype.addFeatures = function(features) {
      var feature, mp, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = features.length; _i < _len; _i++) {
        feature = features[_i];
        if (typeof feature.geometry === 'string') {
          feature.geometry = $.parseJSON(feature.geometry);
        }
        mp = new this.polygonClass(feature);
        this.items[feature.properties.gid] = mp;
        _results.push(this.L.addLayer(mp.L));
      }
      return _results;
    };

    return MultiPolygonCollection;

  })();

  window.MultiPolygonCollection = MultiPolygonCollection;

  window.ILC = {
    map: null,
    industrial: null,
    naics_trends: null,
    visibleIndustrialFeatures: [],
    _pxScale: null,
    layers: {},
    vectorLayers: {},
    currentRasterLayer: null,
    currentRasterKey: null,
    currentNAICS3: null,
    colormap: function() {
      return Colormap.loaded[Colormap.currentIndex];
    },
    pxScale: function() {
      var b, dx, dy, lat, lng, map, ne, pb, sw;
      map = ILC.map;
      pb = map.getPixelBounds();
      b = map.getBounds();
      ne = b.getNorthEast();
      sw = b.getSouthWest();
      lat = ne.lat - sw.lat;
      lng = ne.lng - sw.lng;
      dx = pb.max.x - pb.min.x;
      dy = pb.max.y - pb.min.y;
      if (lat > lng) {
        this._pxScale = dy / lat;
      } else {
        this._pxScale = dx / lng;
      }
      return this._pxScale;
    },
    datapath: function(dataset) {
      return "data/" + dataset;
    },
    initialize: function(opts) {
      var dataset, limit;
      dataset = opts.dataset, limit = opts.limit;
      this.initLeaflet('leaflet-map');
      ILC.addPolygons(dataset, limit);
      ILC.loadData(dataset);
      this.graphs.naics_trends.initialize();
      this.graphs.histogram.initialize();
      this.graphs.demography.race.initialize();
      this.graphs.demography.occupation.initialize();
      return this.pxScale();
    },
    initLeaflet: function(id) {
      var _this = this;
      this.map = L.map(id, {
        zoomControl: false
      });
      L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/map//{z}/{x}/{y}.png', {
        attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>.  Tiles Courtesy of <a href="http://www.mapquest.com/" target="_blank">MapQuest</a> <img src="http://developer.mapquest.com/content/osm/mq_logo.png">',
        minZoom: Settings.baseMinZoom,
        subdomains: '1234',
        opacity: 0.5
      }).addTo(this.map);
      this.map.on('click', function(e) {
        IndustrialPolygon.clearActive(e.originalEvent);
        ILC.graphs.hideNonHistogram();
        return ILC.graphs.histogram.updateActive();
      }).on('moveend', function(e) {
        if (_this.graphs.histogram.layout != null) {
          return _this.graphs.histogram.update();
        }
      }).on('zoomend', function(e) {
        var zoom;
        zoom = e.target._zoom;
        ILC.resizeDivIcons(zoom);
        ILC.updateVisibleFeatures();
        if (ILC.currentRasterLayer != null) {
          if (_this.map.getZoom() > Settings.rasterMaxZoom) {
            return ILC.graphs.show();
          } else {
            return ILC.graphs.hide();
          }
        }
      }).on('overlayadd', function(e) {
        return console.log('add', e);
      }).on('overlayremove', function(e) {
        return console.log('remove', e);
      }).on('baselayerchange', function(e) {
        return console.log('change', e);
      });
      return this.map;
    },
    resizeDivIcons: function(zoom) {
      var size;
      size = Math.max(4, (zoom - 11) * 2 + 6);
      return $('.brownfield-divicon').css({
        width: size,
        height: size,
        'margin-left': -size / 2,
        'margin-top': -size / 2
      });
    },
    resetLegend: function() {
      return $('#legend .colormap').html('').append(this.colormap().legendHTML());
    },
    updateVisibleFeatures: function() {
      var f, group, id, previousNum, pxScale, _ref;
      previousNum = this.visibleIndustrialFeatures.length;
      group = ILC.industrial;
      group.L.clearLayers();
      pxScale = this.pxScale();
      this.visibleIndustrialFeatures = (function() {
        var _ref, _results;
        _ref = group.items;
        _results = [];
        for (id in _ref) {
          f = _ref[id];
          if (!(f.size_metric * pxScale > Settings.minSizeMetric && (this.currentNAICS3 === null || f.naics3 === this.currentNAICS3))) {
            continue;
          }
          f.pxSizeEstimate = f.size_metric * pxScale;
          group.L.addLayer(f.L);
          _results.push(f);
        }
        return _results;
      }).call(this);
      if ((this.colormap() != null) && this.visibleIndustrialFeatures.length > previousNum) {
        this.updateFeatures();
      }
      if ((IndustrialPolygon.activeFeature != null) && !(_ref = IndustrialPolygon.activeFeature.gid, __indexOf.call(this.visibleIndustrialFeatures.map(function(f) {
        if (f != null) {
          return f.gid;
        } else {
          return null;
        }
      }), _ref) >= 0)) {
        IndustrialPolygon.clearActive();
        return ILC.graphs.hideNonHistogram();
      }
    },
    updateFeatures: function() {
      var colormap, f, features, id, _results;
      features = this.visibleIndustrialFeatures;
      colormap = this.colormap();
      _results = [];
      for (id in features) {
        f = features[id];
        if (!((IndustrialPolygon.activeFeature != null) && IndustrialPolygon.activeFeature.gid === f.gid)) {
          _results.push(f.updateColor(colormap));
        }
      }
      return _results;
    },
    getRiskRange: function() {
      var extent, f, features, id, risks;
      features = this.industrial.items;
      risks = (function() {
        var _results;
        _results = [];
        for (id in features) {
          f = features[id];
          _results.push(f.risk());
        }
        return _results;
      })();
      extent = [Math.min.apply(null, risks), Math.max.apply(null, risks)];
      return extent;
    },
    _updateLegendVisibility: function() {
      var other;
      other = $(".other-legends");
      if (other.find('.legend-container.active').length === 0) {
        return other.fadeOut();
      } else {
        return other.fadeIn();
      }
    },
    addVector: function(key) {
      ILC.map.addLayer(ILC.vectorLayers[key]);
      $('#legend').find(".legend-container." + key).addClass('active').fadeIn();
      this._updateLegendVisibility();
      if (key === 'brownfields') {
        return ILC.resizeDivIcons(ILC.map.getZoom());
      }
    },
    removeVector: function(key) {
      ILC.map.removeLayer(ILC.vectorLayers[key]);
      $('#legend').find(".legend-container." + key).removeClass('active').fadeOut();
      return this._updateLegendVisibility();
    },
    setRaster: function(id, fmt, opts) {
      var urlTemplate;
      fmt = fmt || "png";
      if (id === this.currentRasterKey) {
        return;
      }
      if (this.currentRasterLayer != null) {
        this.map.removeLayer(this.currentRasterLayer);
        $('#legend .raster-legends img').hide();
      }
      if ((id != null) && id !== '') {
        urlTemplate = "images/tiles/" + id + "/{z}/{x}/{y}." + fmt;
        this.currentRasterLayer = L.tileLayer(urlTemplate, opts).addTo(this.map);
        ILC.graphs.hide();
        $("#legend .raster-legends img[data-id=" + id + "]").fadeIn();
      } else {
        this.currentRasterLayer = null;
        ILC.graphs.show();
      }
      return this.currentRasterKey = id;
    },
    addPolygons: function(dataset, limit) {
      var calculateStuff, limit_str, loadChunk, map, _i, _results,
        _this = this;
      calculateStuff = function(features) {
        var riskRange;
        riskRange = _this.getRiskRange();
        Colormap.updatePreviews(Settings.initialColorBins);
        Colormap.setCurrent(0);
        ILC.resetLegend();
        return _this.updateFeatures();
      };
      loadChunk = function(i) {
        var res_c, res_i, url_converted, url_industrial;
        url_industrial = _this.datapath(dataset) + ("/json/industrial-" + i + ".geojson");
        url_converted = _this.datapath(dataset) + ("/json/converted-" + i + ".geojson");
        res_i = HTTP.call('GET', url_industrial);
        res_i.success(function(data) {
          var bounds, f, feats;
          if (Settings.requireDemography) {
            feats = (function() {
              var _i, _len, _ref, _results;
              _ref = data.features;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                f = _ref[_i];
                if (f.properties.demography.race.multi != null) {
                  _results.push(f);
                }
              }
              return _results;
            })();
          } else {
            feats = data.features;
          }
          _this.industrial.addFeatures(feats);
          if (true) {
            bounds = _this.industrial.L.getBounds();
            map.fitBounds(bounds);
          }
          ILC.vectorLayers['industrial-parcels'] = _this.industrial.L;
          _this.updateVisibleFeatures();
          return calculateStuff(_this.visibleIndustrialFeatures);
        });
        res_c = HTTP.call('GET', url_converted);
        return res_c.success(function(data) {
          _this.converted.addFeatures(data.features);
          return ILC.vectorLayers['converted-parcels'] = _this.converted.L;
        });
      };
      map = this.map;
      limit_str = limit != null ? '?limit=' + limit : '';
      this.industrial = new MultiPolygonCollection(IndustrialPolygon);
      this.converted = new MultiPolygonCollection(ConvertedPolygon);
      this.industrial.L.addTo(map);
      Colormap.updatePreviews(Settings.initialColorBins);
      Colormap.setCurrent(0);
      _results = [];
      for (i = _i = 0; _i <= 32; i = ++_i) {
        _results.push(loadChunk(i));
      }
      return _results;
    },
    loadData: function(dataset) {
      var $opt, $optgroup, code, code3, codes, groups, list, name, res, title, _i, _j, _len, _len1,
        _this = this;
      res = HTTP.blocking('GET', this.datapath(dataset) + '/naics-trends.json');
      res.success(function(data) {
        _this.naics_trends = data.naics_trends;
        return console.log('NAAAAICS', _this.naics_trends);
      });
      res = HTTP.blocking('GET', '/data/naics-list.json');
      res.success(function(data) {
        return _this.naics_list = data.naics_list;
      });
      res = HTTP.blocking('GET', this.datapath(dataset) + '/json/brownfields.geojson');
      res.success(function(data) {
        _this.layers.brownfields = L.geoJson(data, {
          pointToLayer: function(feature, latlng) {
            return new L.Marker(latlng, {
              clickable: false,
              icon: L.divIcon({
                className: 'brownfield-divicon'
              })
            });
          }
        });
        return ILC.vectorLayers['brownfields'] = _this.layers.brownfields;
      });
      list = (function() {
        var _ref, _results;
        _ref = this.naics_list;
        _results = [];
        for (code in _ref) {
          title = _ref[code];
          if (title !== '???') {
            _results.push([code, title]);
          }
        }
        return _results;
      }).call(this);
      list = list.sort(function(a, b) {
        if (a[1] < b[1]) {
          return -1;
        } else {
          return 1;
        }
      });
      groups = {};
      for (_i = 0, _len = list.length; _i < _len; _i++) {
        line = list[_i];
        code = line[0];
        name = line[1];
        code3 = code.substr(0, 3);
        if (!groups[code3]) {
          groups[code3] = [];
        }
        groups[code3].push(code);
      }
      for (code3 in groups) {
        codes = groups[code3];
        name = this.naics_list[code3];
        $optgroup = $("<optgroup label=\"" + name + "\"></optgroup>");
        for (_j = 0, _len1 = codes.length; _j < _len1; _j++) {
          code = codes[_j];
          name = this.naics_list[code];
          $opt = code === code3 ? "<option value=\"" + code + "\" class=\"primary\">" + name + "</option>" : "<option value=\"" + code + "\">" + name + "</option>";
          $optgroup.append("<option value=\"" + code + "\">" + name + "</option>");
        }
        $('.industry-select').append($optgroup);
      }
      return $('.industry-select').chosen({
        allow_single_deselect: true
      });
    },
    graphs: {
      $container: function() {
        return $('#graphs');
      },
      show: function() {
        return this.$container().fadeIn();
      },
      hide: function() {
        return this.$container().fadeOut();
      },
      hideNonHistogram: function() {
        ILC.graphs.demography.race.hide();
        ILC.graphs.demography.occupation.hide();
        ILC.graphs.naics_trends.hide();
        return $('#legends-and-colormaps').fadeIn();
      },
      naics_trends: {
        $container: function() {
          return $('#naics-trends-graph');
        },
        lines: {
          county: null,
          state: null,
          nation: null
        },
        svg: null,
        xAxis: function() {
          return d3.svg.axis().scale(this.x).orient('bottom').tickValues([1990, 2000, 2010]).tickFormat(d3.format("d"));
        },
        yAxis: function() {
          return d3.svg.axis().scale(this.y).orient('left').tickValues([1]).ticks(4).tickSubdivide(0.25);
        },
        hide: function() {
          return this.$container().fadeOut();
        },
        show: function() {
          return this.$container().fadeIn();
        },
        initialize: function() {
          var height, lineStyle, margin, width,
            _this = this;
          margin = {
            top: 5,
            left: 25,
            bottom: 25,
            right: 25
          };
          width = Settings.graphWidth;
          height = Settings.lineGraphHeight;
          this.x = d3.scale.linear().domain([1990, 2010]).range([0, width - margin.left - margin.right]);
          this.y = d3.scale.linear().domain([0, 3]).range([height - margin.top - margin.bottom, 0]);
          this.lines.county = d3.svg.line().x(function(d) {
            return _this.x(d.year);
          }).y(function(d) {
            return _this.y(d.value);
          });
          this.lines.state = d3.svg.line().x(function(d) {
            return _this.x(d.year);
          }).y(function(d) {
            return _this.y(d.value);
          });
          this.lines.nation = d3.svg.line().x(function(d) {
            return _this.x(d.year);
          }).y(function(d) {
            return _this.y(d.value);
          });
          this.svg = d3.select('#naics-trends-graph').append('svg:svg').attr('width', width).attr('height', height).append('g').attr('transform', "translate(" + margin.left + ", " + margin.top + ")");
          lineStyle = function(name) {
            return {
              fill: 'none',
              "class": name,
              stroke: (name === 'county' ? makeColorString(Settings.graphs.trends.colors[0]) : name === 'state' ? makeColorString(Settings.graphs.trends.colors[1]) : makeColorString(Settings.graphs.trends.colors[2]))
            };
          };
          this.svg.append('path').attr(lineStyle('county'));
          this.svg.append('path').attr(lineStyle('state'));
          this.svg.append('path').attr(lineStyle('nation'));
          this.svg.append("g").attr("class", "x axis").attr("transform", "translate(0," + (height - margin.bottom - margin.top) + ")").call(this.xAxis());
          return this.svg.append("g").attr("class", "y axis").call(this.yAxis());
        },
        setNAICS: function(naics_code) {
          var baseIndex, baseX, baseYear, countywide, countywide_base_year, d, data, datum, extent, k, max, meta, min, naicsTitle, nationwide, statewide, statewide_base_year, which, _i, _len;
          if ((naics_code != null) && naics_code > 0) {
            this.show();
            naicsTitle = ILC.naics_list[naics_code];
            this.$container().find('.info .naics-title').text("" + naics_code + " - " + naicsTitle);
            this.$container().find('.naics').text("" + naics_code);
            this.$container().find('.info .naics-filter-select').click(function(e) {
              $('.industry-select').val(naics_code);
              $('.industry-select').trigger("liszt:updated");
              ILC.currentNAICS3 = naics_code.substr(0, 3);
              ILC.updateVisibleFeatures();
              return false;
            });
            console.log(ILC.naics_trends);
            countywide = ILC.naics_trends.countywide[naics_code];
            nationwide = ILC.naics_trends.nationwide[naics_code];
            statewide = ILC.naics_trends.statewide["31-33"];
            data = {
              county: countywide != null ? countywide.emp_growth : [],
              state: statewide != null ? statewide.emp_growth : [],
              nation: nationwide != null ? nationwide.emp_growth : []
            };
            countywide_base_year = countywide != null ? countywide.base_year : null;
            statewide_base_year = statewide != null ? statewide.base_year : null;
            meta = {
              county: {
                baseYear: countywide_base_year
              },
              state: {
                baseYear: statewide_base_year
              },
              nation: {
                baseYear: 1990
              }
            };
            baseYear = Math.max(countywide_base_year, statewide_base_year);
            baseIndex = baseYear - 1990;
            baseX = this.x(baseYear);
            min = 999;
            max = -999;
            for (k in data) {
              datum = data[k];
              if (datum != null) {
                for (_i = 0, _len = datum.length; _i < _len; _i++) {
                  d = datum[_i];
                  if (baseIndex > 0) {
                    d.value /= datum[baseIndex].value;
                  }
                  if (d.value < min) {
                    min = d.value;
                  }
                  if (d.value > max) {
                    max = d.value;
                  }
                }
              }
            }
            extent = [0, max];
            this.y.domain(extent);
            this.svg.select('.y.axis').transition().duration(777).attr('transform', "translate(" + baseX + ", 0)").call(this.yAxis());
            for (which in data) {
              datum = data[which];
              console.debug(data, this.svg);
              this.svg.select("path." + which).datum(datum).transition().duration(777).attr('d', this.lines[which]);
            }
            return this.show();
          } else {
            this.hide();
          }
        }
      },
      demography: {
        race: new StackedBarChart({
          width: Settings.barGraphWidth,
          height: 120,
          name: 'race',
          legendData: {
            white: {
              label: 'White'
            },
            black: {
              label: 'Black'
            },
            asian: {
              label: 'Asian'
            },
            multi: {
              label: 'Mixed'
            },
            other: {
              label: 'Other'
            }
          }
        }),
        occupation: new StackedBarChart({
          width: Settings.barGraphWidth,
          height: 120,
          name: 'occupation',
          legendData: {
            management: {
              label: 'Management'
            },
            service: {
              label: 'Service'
            },
            office: {
              label: 'Office'
            },
            construction: {
              label: 'Construction'
            },
            manufacturing: {
              label: 'Production'
            }
          }
        })
      },
      histogram: {
        x: null,
        y: null,
        layout: null,
        height: null,
        currentData: null,
        selector: '#risk-histogram',
        $container: function() {
          return $(this.selector);
        },
        $rects: function() {
          return $(this.selector).find(".bar rect");
        },
        update: function() {
          var d, data, f, features, mapBounds, risk, values;
          mapBounds = ILC.map.getBounds();
          features = (function() {
            var _i, _len, _ref, _results;
            _ref = ILC.visibleIndustrialFeatures;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              f = _ref[_i];
              if ((f.risk() != null) && f.L.getBounds().intersects(mapBounds)) {
                _results.push(f);
              }
            }
            return _results;
          })();
          values = features.map(function(f) {
            return f.risk();
          });
          data = this.layout(values);
          if ((IndustrialPolygon.activeFeature != null)) {
            risk = IndustrialPolygon.activeFeature.risk();
            for (i in data) {
              d = data[i];
              d.active = d.x <= risk && risk <= d.x + d.dx;
            }
          }
          this.setData(data);
          return this.updateActive();
        },
        setData: function(data) {
          var bar,
            _this = this;
          bar = d3.selectAll("" + this.selector + " .bar").data(data);
          this.currentData = data;
          return bar.transition().duration(777).attr("transform", function(d) {
            return "translate(" + _this.x(d.x) + "," + _this.y(d.y) + ")";
          }).select('rect').attr('height', function(d) {
            return _this.barHeight - _this.y(d.y);
          }).attr('fill', function(d) {
            if (d.active) {
              return Settings.activeColor;
            } else {
              return ILC.colormap().getColorString(d.x);
            }
          });
        },
        updateActive: function() {
          var d, risk, _ref, _ref1;
          if ((IndustrialPolygon.activeFeature != null)) {
            risk = IndustrialPolygon.activeFeature.risk();
            _ref = this.currentData;
            for (i in _ref) {
              d = _ref[i];
              d.active = d.x <= risk && risk <= d.x + d.dx;
            }
          } else {
            _ref1 = this.currentData;
            for (i in _ref1) {
              d = _ref1[i];
              d.active = false;
            }
          }
          return this.setData(this.currentData);
        },
        initialize: function() {
          var axisSpace, bar, barHeight, data, formatCount, height, hist, margin, svg, sz, values, width, x, xAxis, y;
          sz = Settings.histogramMaxValue;
          values = d3.range(1000).map(function(x) {
            return sz * d3.random.irwinHall(10)(x);
          });
          formatCount = d3.format(",.0f");
          axisSpace = 25;
          margin = {
            top: 0,
            right: 20,
            bottom: 20,
            left: 20
          };
          width = Settings.graphWidth;
          height = width / 2;
          barHeight = height;
          x = d3.scale.linear().domain([0, sz]).range([0, width]);
          hist = d3.layout.histogram().bins(x.ticks(20)).frequency(false);
          data = hist(values);
          y = d3.scale.linear().domain([0, 1]).range([barHeight, 0]);
          xAxis = d3.svg.axis().scale(x).orient("bottom").ticks(1).tickFormat(d3.format("p")).tickSubdivide(0.25);
          svg = d3.select(this.selector).append("svg").attr("width", width + margin.left + margin.right).attr("height", height + margin.top + margin.bottom).append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");
          bar = svg.selectAll(".bar").data(data).enter().append("g").attr("class", "bar").attr("transform", function(d) {
            return "translate(" + x(d.x) + "," + y(d.y) + ")";
          });
          bar.append("rect").attr("x", 1).attr("width", x(data[0].dx) - 1).attr("height", function(d) {
            return barHeight - y(d.y);
          }).attr('stroke', '#333').attr('stroke-width', 1).attr('fill', function(d) {
            return ILC.colormap().getColorString(d.x);
          });
          svg.append("g").attr("class", "x axis").attr("transform", "translate(" + 0 + "," + barHeight + ")").call(xAxis);
          this.x = x;
          this.y = y;
          this.layout = hist;
          this.currentData = data;
          this.height = height;
          return this.barHeight = barHeight;
        }
      }
    }
  };

  slugs = {
    polygons: function(dataset) {
      return 'industrial-polygons-' + dataset;
    }
  };

  $(function() {
    var abbr, color, geocoder, label, vec_btn_container, _ref;
    geocoder = new google.maps.Geocoder();
    $('#legends-and-colormaps .toggle-colormaps').click(function(e) {
      if ($(this).hasClass('active')) {
        $('#colormap-picker').fadeOut();
        return $(this).text("Show colormap picker");
      } else {
        $('#colormap-picker').fadeIn();
        return $(this).text("Hide colormap picker");
      }
    });
    $('#colormap-picker select.num-bins').change(function(e) {
      var N;
      N = $(this).val();
      IndustrialPolygon.clearActive();
      ILC.graphs.hideNonHistogram();
      Colormap.updatePreviews(N, null);
      ILC.resetLegend();
      ILC.updateFeatures();
      return ILC.graphs.histogram.update();
    });
    $('#colormap-picker .colormaps').on('click', '.colormap-preview', function(e) {
      var id, seg;
      id = $(this).attr('data-id');
      seg = $(this).attr('data-segmentation');
      Colormap.setCurrent(id);
      ILC.resetLegend();
      ILC.updateFeatures();
      return ILC.graphs.histogram.update();
    });
    $('#colormap-picker select.segmentation').change(function(e) {
      var seg;
      seg = $(this).val();
      IndustrialPolygon.clearActive();
      ILC.graphs.hideNonHistogram();
      Colormap.updatePreviews(null, seg);
      ILC.resetLegend();
      ILC.updateFeatures();
      return ILC.graphs.histogram.update();
    });
    $('.risk-select').on('change', function(e) {
      var suffix;
      IndustrialPolygon.riskType = $(this).val();
      IndustrialPolygon.clearActive();
      ILC.graphs.hideNonHistogram();
      Colormap.updatePreviews(null, null);
      ILC.resetLegend();
      ILC.updateFeatures();
      ILC.graphs.histogram.update();
      suffix = (function() {
        switch (IndustrialPolygon.riskType) {
          case 'risk_res':
            return ' to Residential';
          case 'risk_com':
            return ' to Commercial';
          default:
            return '';
        }
      })();
      return $('.legend-container.industrial-parcels .title').html('Probability of conversion<br/>from Industrial' + suffix);
    });
    $('.industry-select').on('change', function(e) {
      var val;
      val = $(this).val().substr(0, 3) || null;
      $(this).val(val).trigger("liszt:updated");
      ILC.currentNAICS3 = val;
      return ILC.updateVisibleFeatures();
    });
    $('.togglable-panel').each(function(i, el) {
      var parent;
      parent = $(el);
      parent.find('a.collapse').on('click', function(e) {
        parent.find('.collapsed').show();
        parent.find('.expanded').hide();
        return false;
      });
      return parent.find('a.expand').on('click', function(e) {
        parent.find('.collapsed').hide();
        parent.find('.expanded').show();
        return false;
      });
    });
    vec_btn_container = $('#vector-picker .vector-choices');
    vec_btn_container.find('.btn').on('click', function(e) {
      var key;
      key = $(this).attr('data-id');
      if ($(this).hasClass('active')) {
        return ILC.removeVector(key);
      } else {
        return ILC.addVector(key);
      }
    });
    $('#raster-picker .raster-choices .btn').on('click', function(e) {
      var fmt, key;
      key = $(this).attr('data-id');
      fmt = $(this).attr('data-fmt');
      if (key !== ILC.currentRasterKey) {
        return ILC.setRaster(key, fmt, {
          minZoom: Settings.baseMinZoom,
          maxZoom: Settings.rasterMaxZoom,
          opacity: 1.0,
          tms: true
        });
      }
    });
    $('#address-picker form').on('submit', function(e) {
      var address;
      e.preventDefault();
      address = $(this).find('.address').val();
      geocoder.geocode({
        address: address
      }, function(results, status) {
        var latlng, loc;
        loc = results[0].geometry.location;
        latlng = [loc.jb, loc.kb];
        return ILC.map.setView(latlng, 14);
      });
      return false;
    });
    _ref = Settings.convertedCategories;
    for (abbr in _ref) {
      label = _ref[abbr];
      color = Settings.convertedColors[abbr];
      $('.legend-container.converted-parcels ul.legend').append("<li>\n	<div class=\"color\" style=\"border: 3px solid " + color + "\"></div>\n	<div class=\"label\">" + label + "</div>\n</li>");
    }
    HTTP.setup();
    $('#control-panels .left').children().each(function() {
      return $('.leaflet-control-container .leaflet-left.leaflet-top').append($(this));
    });
    console.log("here we go");
    return $(function() {
      return ILC.initialize({
        dataset: window.location.hash.substring(1) || 'meck',
        limit: 500
      });
    });
  });

}).call(this);
