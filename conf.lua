function love.conf(t)
    t.window.title = "Theta Battle Tool" -- Game window title
    t.window.width = 1280                -- Window width
    t.window.height = 960                -- Window height
    t.window.fullscreen = false          -- Fullscreen mode (false for windowed)
    t.window.vsync = true                -- Enable vertical sync
    t.window.resizable = true
    t.highdpi = true                     -- Necessary for proper scaling.
end