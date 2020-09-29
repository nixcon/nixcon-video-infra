local array = require "util.array"
local datetime = require "util.datetime"
local json = require "util.json"

local type_header = [[
# HELP participant_audio_muted Set to 1 if a participant has muted audio
# TYPE participant_audio_muted gauge

# HELP participant_video_muted Set to 1 if a participant has muted video
# TYPE participant_video_muted gauge

# HELP participant_video_desktop Set to 1 if a participant is screen sharing
# TYPE participant_video_desktop gauge

# HELP participant_hand_raised Set to 1 if a participant is raising their hand
# TYPE participant_hand_raised gauge
]]

function escape(str)
    local backslash_escaped = string.gsub(str, "\\", "\\\\")
    local newline_escaped = string.gsub(backslash_escaped, "\n", "\\n")
    local quote_escaped = string.gsub(newline_escaped, "\"", "\\\"")
    return quote_escaped
end

function get_stats(event)
    local component
    for name, host in pairs(hosts) do
        if name:sub(1, #"conference.") == "conference." then
            component = host
            break
        end
    end

    local output = type_header .. "\n"

    for room in component.modules.muc.all_rooms() do
        for _, occupant in room:each_occupant() do
            for jid, session in occupant:each_session() do
                local audiomuted = (session:get_child_text("audiomuted", "http://jitsi.org/jitmeet/audio") == "true" and 1 or 0)
                local videomuted = (session:get_child_text("videomuted", "http://jitsi.org/jitmeet/video") == "true" and 1 or 0)
                local videodesktop = (session:get_child_text("videoType", "http://jitsi.org/jitmeet/video") == "desktop" and 1 or 0)
                local handraised = (session:get_child_text("jitsi_participant_raisedHand") == "true" and 1 or 0)
                local nick = escape(session:get_child_text("nick", "http://jabber.org/protocol/nick") or "")
                local stats_id = escape(session:get_child_text("stats-id") or "")

                local data = {
                    jid = escape(jid),
                    room = escape(room.jid),
                    statsid = stats_id,
                    nick = nick,

                    audiomuted = audiomuted,
                    videomuted = videomuted,
                    videodesktop = videodesktop,
                    handraised = handraised,
                }

                local to_send = [[
participant_audio_muted{room="%room%",jid="%jid%",statsid="%statsid%",nick="%nick%"} %audiomuted%
participant_video_muted{room="%room%",jid="%jid%",statsid="%statsid%",nick="%nick%"} %videomuted%
participant_video_desktop{room="%room%",jid="%jid%",statsid="%statsid%",nick="%nick%"} %videodesktop%
participant_hand_raised{room="%room%",jid="%jid%",statsid="%statsid%",nick="%nick%"} %handraised%
                ]]

                for key, value in pairs(data) do
                    to_send = string.gsub(to_send, "%%" .. key .. "%%", value)
                end

                output = output .. to_send .. "\n"
            end
        end
    end

    return { status_code = 200; body = output }
end

function module.load()
    module:depends("http")
    module:provides("http", {
        default_path = "/";
        route = {
            ["GET stats"] = get_stats;
        };
    });
end


