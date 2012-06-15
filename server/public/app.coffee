class Route extends Backbone.Model
class Routes extends Backbone.Collection
    model: Route
    url: '/nearest'
    comparator: (route) -> route.get 'route'

class RouteView extends Backbone.View
    render: ->
        return _.template $('#route').html(), @model.toJSON()

class RouteListView extends Backbone.View
    el: '#busses'
#    template: _.template($('#meh').html())

    initialize: ->
        @collection.sort { silent: true }
        @collection.on 'reset', @render

    render: =>
        @$el.empty()
        @collection.each (route) => 
            rv = new RouteView 
                model: route

            @$el.append(rv.render())

class AppRouter extends Backbone.Router
    routes:
       '*path': 'defaultRoute'

    defaultRoute: (path) -> console.log path


class AppView extends Backbone.View
    collections: {}
    views: {}

    initialize: ->
        if Modernizr.geolocation
            new AppRouter
            Backbone.history.start { pushState: true }

            navigator.geolocation.getCurrentPosition (position) =>
                #console.log position
                #console.log @routes
        else
            # No location


        @collections.routes = new Routes
        @views.routes = new RouteListView({ collection: @collections.routes })
        @collections.routes.fetch()

$ -> window.App = new AppView()
