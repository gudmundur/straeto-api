# api.gulur.is

Unofficial restful service for bus times in and around Reykjavík. This service is used by

* [Gulur.is](http://gulur.is)

## /stops/

List of all stops.

#### Examples

* [http://api.gulur.is/stops/](http://api.gulur.is/stops/)
	
## /stops/{id}

Information about a specific stop and bus stop times for that particular stop.

#### Parameters

* **range** - Predefined time ranges which are
	*  *day* - the entire day.
	* *restOfDay* - past 15 minutes till the end of day.
	* *now* - from past 15 minutes to an hour from now.
* **from** - From a certain time (ISO 8601)
* **to** - To a certain time (ISO 8601)

#### Examples

* [http://api.gulur.is/stops/90000295](http://api.gulur.is/stops/90000295)
* [http://api.gulur.is/stops/90000295?range=restOfDay](http://api.gulur.is/stops/90000295?range=restOfDay)
* [http://api.gulur.is/stops/90000295?from=2012-09-10T14&to=2012-09-10T15:30](http://api.gulur.is/stops/90000295?from=2012-09-10T14&to=2012-09-10T15:30)

## /nearest

The nearest stops to a location.

#### Parameters

* **latitude** - Required
* **longitude** - Required
* **radius** - Radius to search within (default: 500m)

#### Examples

* [http://api.gulur.is/nearest?latitude=64.14325300000216&longitude=-21.914210999995465&radius=750](http://api.gulur.is/nearest?latitude=64.14325300000216&longitude=-21.914210999995465&radius=750)

## /buses

Stop times for the nearest buses to a location.

#### Parameters

* **latitude** - Required
* **longitude** - Required
* **radius** - Radius to search within (default: 500m)
* **range** - Predefined time ranges which are
	*  *day* - the entire day.
	* *restOfDay* - past 15 minutes till the end of day.
	* *now* - from past 15 minutes to an hour from now.
* **from** - From a certain time (ISO 8601)
* **to** - To a certain time (ISO 8601)


#### Examples

*  [http://api.gulur.is/buses?latitude=64.14325300000216&longitude=-21.914210999995465](http://api.gulur.is/buses?latitude=64.14325300000216&longitude=-21.914210999995465)
*  [http://api.gulur.is/buses?latitude=64.14325300000216&longitude=-21.914210999995465&range=restOfDay](http://api.gulur.is/buses?latitude=64.14325300000216&longitude=-21.914210999995465&range=restOfDay)