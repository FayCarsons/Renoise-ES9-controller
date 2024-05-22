local connection_timeout = 2000

local client, socket_error = renoise.Socket.create_client(
  "localhost", 8000, renoise.Socket.PROTOCOL_TCP, connection_timeout
)

if socket_error then
  renoise.app():show_warning(socket_error)
  return
end

local function set_es9(output, value)
  local _, err = client:send(string.format("set/%d/%f", output, value))
  if err then
    renoise.app():show_warning(err)
  end
end

local TRACK_TO_MONITOR = 1

local function on_note(note)
  if not note.is_empty then
    set_es9(
      math.floor(note.panning_value / 16),
      (note.note_value - 48) / 24
    )
  end
end

local function monitor(index)
  if index == TRACK_TO_MONITOR then
    local song = renoise.song()

    for _, line in ipairs(song.pattern_iterator:lines_in_track(index - 1)) do
      for _, note in ipairs(line.note_columns) do
        note.value_observable:remove_notifier(on_note)
        note.value_observable:add_notifier(function() on_note(note) end)
      end
    end
  end
end

renoise.tool().app_new_document_observable:add_notifier(function()
  local song = renoise.song()

  song.selected_track_observable:add_notifier(function()
    monitor(song.selected_track_index)
  end)

  monitor(song.selected_track_index)
end)

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Set Track as ES9 Controller",
  invoke = function()
    local song = renoise.song()
    TRACK_TO_MONITOR = song.selected_track_index
    renoise.app():show_message(string.format("Track %d is now set as ES9 Controller", TRACK_TO_MONITOR))
  end
}

--[[

renoise.tool():add_keybinding {
  name = "Global:Tools:Set Track as ES9 Controller",
  invoke = function()
    local song = renoise.song()
    TRACK_TO_MONITOR = song.selected_track_index
    renoise.app():show_message(string.format("Track %d is now set as ES9 Controller"))
  end
}

--]]
