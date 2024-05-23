-- Instantiate UDP client singleton if not already instantiated
if ~_G.ES9_sender then
  local connection_timeout = 2000

  local client, socket_error = renoise.Socket.create_client(
    "127.0.0.1", 8080, renoise.Socket.PROTOCOL_UDP, connection_timeout
  )
  if socket_error then
    renoise.app():show_warning("CANT INITIALIZE SOCKET " .. socket_error)
  else
    _G.ES9_sender = client
  end
end

local client = _G.ES9_sender

-- Function to convert an integer to a byte string
local function int_to_bytes(value, num_bytes)
  local bytes = {}
  for i = num_bytes, 1, -1 do
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
  return int_to_bytes(v, 4)
end

-- Sends message to Rust server via UDP client
-- format NULL_BYTE{8 byte integer}{8 byte float}NULL_BYTE
-- integer 'output' is note # % 12 with 0 -- 7 / C -- G# are valid regardless of octave
-- float 'value' is all 4 bytes of effect column ?
local function set_es9(output, value)
  local buff = '\0'
  local int_bytes = int_to_bytes(output, 8)
  local float_bytes = float_to_bytes(value)
  print(string.format("{channel: { int: %d, bytes: %a }, value: { float: %f, bytes: %a }}", output, int_bytes, value,
    float_bytes))
  buff = buff .. int_bytes .. float_bytes .. '\0'
  local _, err = client:send(buff)
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

local function monitor(index)
  local song = renoise.song()

  for pos, column in song.pattern_iterator:lines_in_track(index) do
    -- TODO: Not sure what to do here, the idea is to add a notifier to every note in
    -- the selected track so that when a note
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
