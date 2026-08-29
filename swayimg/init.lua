dofile('/usr/share/swayimg/example.lua')

swayimg.text.visible = false

local function shell_quote(value)
  return "'" .. value:gsub("'", "'\"'\"'") .. "'"
end

local function trash_image(image)
  if not image then
    return
  end

  local result = os.execute('/usr/bin/trash-put -- ' .. shell_quote(image.path))
  if result == true or result == 0 then
    swayimg.imagelist.remove(image.path)
    swayimg.text.status = 'Moved to trash: ' .. image.path
  else
    swayimg.text.status = 'Failed to trash: ' .. image.path
  end
end

swayimg.viewer.on_key('Delete', function()
  trash_image(swayimg.viewer.get_image())
end)

swayimg.gallery.on_key('Delete', function()
  trash_image(swayimg.gallery.get_image())
end)

swayimg.viewer.on_key('left', function()
  swayimg.viewer.open('prev')
end)

swayimg.viewer.on_key('right', function()
  swayimg.viewer.open('next')
end)

swayimg.viewer.on_key('prior', function()
  local pos = swayimg.viewer.get_position()
  swayimg.viewer.set_abs_position(pos.x + 10, pos.y)
end)

swayimg.viewer.on_key('next', function()
  local pos = swayimg.viewer.get_position()
  swayimg.viewer.set_abs_position(pos.x - 10, pos.y)
end)
