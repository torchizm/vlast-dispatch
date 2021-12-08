# vlast-dispatch
FiveM Police old dispatch system made by TORCHIZM for discord.gg/vlast

* Easy usage
* Instant mark notification location on the map with [ALT] key
* Succession system
* Mark location of old notifications with popup menu 
* Built-In shots fired notifications

### Notification Export:

```lua
local ped = PlayerPedId()
local playerPos = GetEntityCoords(ped)
local id = math.random(1, 99999)

data = {
    id = id,
    code = 1,
    description = "Ateş sesleri duyuldu",
    location = "55. Cadde",
    coords = playerPos
}
TriggerServerEvent("vlast-dispatch:add-notification", data, "police")
```

-----
> Notifications
![Notifications](/readme/1.png)
-----
> Popup Menu
![Popup Menu](/readme/2.png)
-----
> Code command with easy config
![Code](/readme/kod-1.png)
> Code command example
![Example](/readme/kod-2.png)