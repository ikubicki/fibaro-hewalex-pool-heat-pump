--[[
Internationalization tool
@author ikubicki
]]
class 'i18n'

function i18n:new(langCode)
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
        ['name'] = 'Hewalex PCWB czujnik temperatury',
        ['refresh'] = 'Aktualizuj',
        ['please-wait'] = 'Proszę czekać...',
        ['device-updated'] = 'Zaktualizowano dane czujnika',
        ['device-unavailable'] = 'Urządzenie niedostepne',
        ['device-off'] = 'Urządzenie wyłączone',
        ['temperature-set'] = 'Temperatura grzania %.1fº%s',
        ['temperature-inlet'] = 'Temperatura na wejściu %.1fº%s',
        ['temperature-outlet'] = 'Temperatura na wyjściu %.1fº%s',
        ['temperature-ambient'] = 'Temperatura otoczenia %.1fº%s',
    },
    en = {
        ['name'] = 'Hewalex Pool Heat Pump temperature sensor',
        ['refresh'] = 'Refresh data',
        ['please-wait'] = 'Please wait...',
        ['device-updated'] = 'Temperature sensor updated',
        ['device-unavailable'] = 'Device unavailable',
        ['device-off'] = 'Device turned off',
        ['temperature-set'] = 'Heating temperature set to %.1fº%s',
        ['temperature-inlet'] = 'Inlet temperature %.1fº%s',
        ['temperature-outlet'] = 'Outlet temperature %.1fº%s',
        ['temperature-ambient'] = 'Ambient temperature %.1fº%s',
    },
    de = {
        ['name'] = 'Hewalex Poolwärmepumpe temperatursensor',
        ['refresh'] = 'Aktualisieren',
        ['please-wait'] = 'Ein moment bitte...',
        ['device-updated'] = 'Temperatursensor aktualisiert',
        ['device-unavailable'] = 'Gerät nicht verfügbar',
        ['device-off'] = 'Gerät ausgeschaltet',
        ['temperature-set'] = 'Heiztemperatur eingestellt auf %.1fº%s',
        ['temperature-inlet'] = 'Einlasstemperatur %.1fº%s',
        ['temperature-outlet'] = 'Austrittstemperatur %.1fº%s',
        ['temperature-ambient'] = 'Umgebungstemperatur %.1fº%s',
    }
}