import Toybox.Activity;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class CO2ReducedView extends WatchUi.SimpleDataField {

	// https://www.epa.gov/energy/greenhouse-gases-equivalencies-calculator-calculations-and-references
	hidden var GRAMS_CO2_PER_US_GALLON_OF_GASOLINE = 8887.0;
	hidden var GRAMS_CO2_PER_US_GALLON_OF_DIESEL = 10180.0;
	
	hidden var METERS_IN_A_MILE = 1609.344;
	hidden var GRAMS_IN_A_KILOGRAM = 1000.0;
	hidden var GRAMS_IN_A_POUND = 453.59237;
	
	hidden var mDistanceUnits = System.UNIT_STATUTE;
	
	hidden var mCO2ReducedFieldMetric = null;
	hidden var mCO2ReducedFieldStatute = null;
	hidden var CO2_REDUCED_FIELD_METRIC_ID = 0;
	hidden var CO2_REDUCED_FIELD_STATUTE_ID = 1;

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        
        // set distance units from device settings
        mDistanceUnits = System.getDeviceSettings().distanceUnits;
        
        // create the custom FIT data fields we want to record for CO2 reduction
        mCO2ReducedFieldMetric = createField(
        	WatchUi.loadResource(Rez.Strings.LevelLabelMetric),
            CO2_REDUCED_FIELD_METRIC_ID,
            FitContributor.DATA_TYPE_FLOAT,
            {:mesgType=>FitContributor.MESG_TYPE_RECORD, 
             :units=>WatchUi.loadResource(Rez.Strings.LevelUnitMetric)}
        );
        mCO2ReducedFieldMetric.setData(0.0);
        
        mCO2ReducedFieldStatute = createField(
            WatchUi.loadResource(Rez.Strings.LevelLabelStatute),
            CO2_REDUCED_FIELD_STATUTE_ID,
            FitContributor.DATA_TYPE_FLOAT,
            {:mesgType=>FitContributor.MESG_TYPE_RECORD, 
             :units=>WatchUi.loadResource(Rez.Strings.LevelUnitStatute)}
        );
        mCO2ReducedFieldStatute.setData(0.0);
        
        // set CO2 label
        label = WatchUi.loadResource(Rez.Strings.FieldLabel);
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        
        // load settings values
        var milesPerUSGallon = Application.getApp().getProperty("VehicleEfficiency");
        var fuelType = Application.getApp().getProperty("FuelType");
        
        // convert to meters
        var metersPerUSGallon = milesPerUSGallon * METERS_IN_A_MILE;
        
        // populate CO2 amount based on fuel type
        var gramsCO2PerUSGallon = null;
        if (fuelType == 1) /*Diesel*/ {
        	gramsCO2PerUSGallon = GRAMS_CO2_PER_US_GALLON_OF_DIESEL;
    	} else /*if (fuelType == 0)*/ /*Gasoline*/ {
    		gramsCO2PerUSGallon = GRAMS_CO2_PER_US_GALLON_OF_GASOLINE;
    	}
        
		// get elapsed distance in meters
        var elapsedDistanceMeters = 0.0;
        if (info has :elapsedDistance && info.elapsedDistance != null) {
            elapsedDistanceMeters = info.elapsedDistance;
        } else {
        	elapsedDistanceMeters = 0.0;
        }
        //System.println(elapsedDistanceMeters);
        
        // calculate CO2 reduction
        var equivalentUSGallons = elapsedDistanceMeters / metersPerUSGallon;
        var equivalentGramsCO2 = equivalentUSGallons * gramsCO2PerUSGallon;
        
        // record fields
        var equivalentKgCO2 = equivalentGramsCO2 / GRAMS_IN_A_KILOGRAM;
        var equivalentLbCO2 = equivalentGramsCO2 / GRAMS_IN_A_POUND;
        mCO2ReducedFieldMetric.setData(equivalentKgCO2);
        mCO2ReducedFieldStatute.setData(equivalentLbCO2);
        
        // display CO2 reduction with correct units
        if (mDistanceUnits == System.UNIT_METRIC) {
        	return equivalentKgCO2.format("%.2f") + " " + 
        		WatchUi.loadResource(Rez.Strings.LevelUnitMetric);
        } else /*if (mDistanceUnits == System.UNIT_STATUTE)*/ {
        	return equivalentLbCO2.format("%.2f") + " " + 
        		WatchUi.loadResource(Rez.Strings.LevelUnitStatute);
        }
    }

}