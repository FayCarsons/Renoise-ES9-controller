local function initialize_udp_client()
  local connection_timeout = 2000

  local client, socket_error = renoise.Socket.create_client(
    "127.0.0.1", 8080, renoise.Socket.PROTOCOL_UDP, connection_timeout
  )
  if socket_error then
    renoise.app():show_warning("Cannot initialize UDP client: " .. socket_error)
    return nil
  else
    return client
  end
end

-- Instantiate UDP client singleton if not already instantiated
if not (rawget(_G, "ES9_CLIENT") or nil) then
  local success, client_or_error = pcall(initialize_udp_client)
  if success and client_or_error then
    rawset(_G, "ES9_CLIENT", client_or_error)
  else
    renoise.app():show_warning("Failed to initialize UDP client: " .. client_or_error)
  end
end

local client = _G.ES9_CLIENT

-- Function to convert an integer to a byte string
local function int_to_bytes(value)
  local bytes = {}
  for i = 8, 1, -1 do
    bytes[i] = string.char(value % 256)
    value = math.floor(value / 256)
  end
  return table.concat(bytes)
end

-- Function to convert a float to a byte string
local function float_to_bytes(value)
  local sign = 0
  if value < 0 then
    sign = 1
    value = -value
  end
  local mantissa, exponent = math.frexp(value)
  if value == 0 then
    mantissa = 0
    exponent = 0
  else
    mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 24)
    exponent = exponent + 126
  end
  local v = sign * 0x80000000 + exponent * 0x800000 + mantissa
  return int_to_bytes(v)
end

-- Sends message to Rust server via UDP client
-- format {8 byte integer}{8 byte float}NULL_BYTE
-- integer 'output' is note # % 12 with 0 -- 7 / C -- G# are valid regardless of octave
-- float 'value' is all 4 bytes of effect column ?
local function set_es9(output, value)
  local int_bytes = int_to_bytes(output)
  local float_bytes = float_to_bytes(value)
  print(string.format(
    [[{channel: { int: %d, bytes: 0x%s },
       value: { float: %f, bytes: 0x%s }}]], output, int_bytes, value,
    float_bytes))
  local _, err = client:send(int_bytes .. float_bytes .. '\0')
  if err then
    renoise.app():show_warning(err)
  end
end

-- Note callback
local function on_note(note)
  print(note)
  if not note.is_empty then
    set_es9(
      note.note_value % 12,
      note.effect_column
    )
  end
end

-- NOTE: Definite problem here!!
local function monitor(index)
  local song = renoise.song()

  for pos, column in song.pattern_iterator:lines_in_track(index) do
    -- TODO: Not sure what to do here, the idea is to add a notifier to every note in
    -- the selected track so that when a note plays the on_note callback is
    -- called with that note as an arg
    for _, note in ipairs(line.note_columns) do
      note.value_observable:remove_notifier(on_note)
      note.value_observable:add_notifier(function() on_note(note) end)
    end
  end
end

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Track:Make ES9 controller",
  invoke = function()
    local song = renoise.song()
    if song.selected_track.type ~= renoise.Track.TRACK_TYPE_MASTER and
        song.selected_track.type ~= renoise.Track.TRACK_TYPE_SEND and
        song.selected_track.type ~= renoise.Track.TRACK_TYPE_GROUP
    then
      monitor(song.selected_track_index)
    end
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Make Selected Track ES9 Controller",
  invoke = function()
    local song = renoise.song()
    if song.selected_track.type ~= renoise.Track.TRACK_TYPE_MASTER and
        song.selected_track.type ~= renoise.Track.TRACK_TYPE_SEND and
        song.selected_track.type ~= renoise.Track.TRACK_TYPE_GROUP
    then
      monitor(song.selected_track_index)
      renoise.app():show_message(string.format("Track %d is now set as an ES9 controller!"))
    end
  end
}
