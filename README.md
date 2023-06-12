# Hewalex PCWB QuickApp for Fibaro

This quick application integrates pool heat pump from Hewalex. It allows to control power, silent mode and heat temperature.
Additionally it created three child devices - temperature sensors that allows to control inlet, outlet and ambient temperatures.

It does not allow to control timers. You may automate that using HC3 scenes.

Data updates every 30 seconds by default.

## Configuration

`Username` - email of AquaTemp account

`Password` - password of AquaTemp account

### Optional values

`Interval` - number of minutes defining how often data should be refreshed. This value will be automatically populated on initialization of quick application.

`DeviceID` - device code. This value will be automatically populated if given credentials have access to a single device

## Installation

Follow regular installation process. After virtual device will be added to your Home Center unit, click on Variables and provide Username and Password. Then, click on Search devices button which will pull all information from your Aqua Temp account that includes all devices.

If given account have only a single device associated, `DeviceID` will be automatically populated. Otherwise, you should specify `DeviceID` in QuickApp Variables section.

If you're installing another device, your Username and Password will be automatically populated from previous device.

To access pulled information, go to logs of the device, review detected devices and use proper IDs as variables of the QuickApp.

To change update interval add Interval property or replace existing one (if there's no edit botton).