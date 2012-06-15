(function() {
  var AppRouter, AppView, Route, RouteListView, RouteView, Routes,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Route = (function(_super) {

    __extends(Route, _super);

    Route.name = 'Route';

    function Route() {
      return Route.__super__.constructor.apply(this, arguments);
    }

    return Route;

  })(Backbone.Model);

  Routes = (function(_super) {

    __extends(Routes, _super);

    Routes.name = 'Routes';

    function Routes() {
      return Routes.__super__.constructor.apply(this, arguments);
    }

    Routes.prototype.model = Route;

    Routes.prototype.url = '/nearest';

    Routes.prototype.comparator = function(route) {
      return route.get('route');
    };

    return Routes;

  })(Backbone.Collection);

  RouteView = (function(_super) {

    __extends(RouteView, _super);

    RouteView.name = 'RouteView';

    function RouteView() {
      return RouteView.__super__.constructor.apply(this, arguments);
    }

    RouteView.prototype.render = function() {
      return _.template($('#route').html(), this.model.toJSON());
    };

    return RouteView;

  })(Backbone.View);

  RouteListView = (function(_super) {

    __extends(RouteListView, _super);

    RouteListView.name = 'RouteListView';

    function RouteListView() {
      this.render = __bind(this.render, this);
      return RouteListView.__super__.constructor.apply(this, arguments);
    }

    RouteListView.prototype.el = '#busses';

    RouteListView.prototype.initialize = function() {
      this.collection.sort({
        silent: true
      });
      return this.collection.on('reset', this.render);
    };

    RouteListView.prototype.render = function() {
      var _this = this;
      this.$el.empty();
      return this.collection.each(function(route) {
        var rv;
        rv = new RouteView({
          model: route
        });
        return _this.$el.append(rv.render());
      });
    };

    return RouteListView;

  })(Backbone.View);

  AppRouter = (function(_super) {

    __extends(AppRouter, _super);

    AppRouter.name = 'AppRouter';

    function AppRouter() {
      return AppRouter.__super__.constructor.apply(this, arguments);
    }

    AppRouter.prototype.routes = {
      '*path': 'defaultRoute'
    };

    AppRouter.prototype.defaultRoute = function(path) {
      return console.log(path);
    };

    return AppRouter;

  })(Backbone.Router);

  AppView = (function(_super) {

    __extends(AppView, _super);

    AppView.name = 'AppView';

    function AppView() {
      return AppView.__super__.constructor.apply(this, arguments);
    }

    AppView.prototype.collections = {};

    AppView.prototype.views = {};

    AppView.prototype.initialize = function() {
      var _this = this;
      if (Modernizr.geolocation) {
        new AppRouter;
        Backbone.history.start({
          pushState: true
        });
        navigator.geolocation.getCurrentPosition(function(position) {});
      } else {

      }
      this.collections.routes = new Routes;
      this.views.routes = new RouteListView({
        collection: this.collections.routes
      });
      return this.collections.routes.fetch();
    };

    return AppView;

  })(Backbone.View);

  $(function() {
    return window.App = new AppView();
  });

}).call(this);
