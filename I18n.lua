--[[
Internationalization tool
@author ikubicki
]]
class 'i18n'

function i18n:new(langCode)
    if phrases[langCode] == nil then
        langCode = "en"
    end
    self.phrases = phrases[langCode]
    return self
end

function i18n:get(key)
    if self.phrases[key] then
        return self.phrases[key]
    end
    return key
end

phrases = {
    pl = {
        ['name'] = 'Termostat Hewalex PCWB',
        ['refresh'] = 'Aktualizuj dane',
        ['refreshing'] = 'Proszę czekać...',
        ['device-updated'] = 'Zaktualizowano dane',
        ['device-unavailable'] = 'Urządzenie niedostepne',
        ['last-update'] = 'Ostatnia aktualizacja: %s',
        ['device-off'] = 'Urządzenie wyłączone',
        ['device-error'] = 'Błąd urządzenia: %s',

        ['search-devices'] = 'Szukaj urządzeń',
        ['searching-devices'] = 'Szukam...',
        ['not-configured'] = 'Urządzenie nie skonfigurowane',
        ['check-logs'] = 'Zakończono wyszukiwanie. Sprawdź logi tego urządzenia: %s',
        ['search-row-device'] = '__ URZĄDZENIE %s (# %s) - STAN: %s',
        ['assigning-device'] = 'Automatycznie przypisano kod urządzenia: %s',

        ['device1-label'] = 'Temperatura wejściowa',
        ['device2-label'] = 'Temperatura wyjściowa',
        ['device3-label'] = 'Temperatura otoczenia',
        ['t1'] = 'Temperatura nastawiona: %.1fº%s',
        ['t2'] = 'Temperatura wejściowa: %.1fº%s',
        ['t3'] = 'Temperatura wyjściowa: %.1fº%s',
        ['t4'] = 'Temperatura otoczenia: %.1fº%s'
    },
    en = {
        ['name'] = 'Hewalex Pool Heat Pump thermostat',
        ['refresh'] = 'Refresh data',
        ['refreshing'] = 'Please wait...',
        ['device-updated'] = 'Temperature sensor updated',
        ['device-unavailable'] = 'Device unavailable',
        ['last-update'] = 'Last update: %s',
        ['device-off'] = 'Device turned off',
        ['device-error'] = 'Communication error: %s',

        ['search-devices'] = 'Search devices',
        ['searching-devices'] = 'Searching...',
        ['not-configured'] = 'Device not configured',
        ['check-logs'] = 'Search complete. Check logs of this device: %s',
        ['search-row-device'] = '__ DEVICE %s (# %s) - STATE: %s',
        ['assigning-device'] = 'Automatically assigned device code: %s',

        ['device1-label'] = 'Inlet temperature',
        ['device2-label'] = 'Outlet temperature',
        ['device3-label'] = 'Ambient temperature',
        ['t1'] = 'Setpoint temperature: %.1f º%s',
        ['t2'] = 'Inlet temperature: %.1f º%s',
        ['t3'] = 'Outlet temperature: %.1f º%s',
        ['t4'] = 'Ambient temperature: %.1f º%s'
    }
}