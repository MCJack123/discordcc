if type(discordapi) ~= "table" then os.loadAPI("discordapi") end

local hex = {"F0F0F0", "F2B233", "E57FD8", "99B2F2", "DEDE6C", "7FCC19", "F2B2CC", "4C4C4C", "999999", "4C99B2", "B266E5", "3366CC", "7F664C", "57A64E", "CC4C4C", "191919"}
local rgb = {}
for i=1,16,1 do
  rgb[i] = {tonumber(hex[i]:sub(1, 2), 16), tonumber(hex[i]:sub(3, 4), 16), tonumber(hex[i]:sub(5, 6), 16)}
end

colors.fromRGB = function (r, g, b)
  local dist = 1e100
  local d = 1e100
  local color = -1
  for i=1,16,1 do
    d = math.sqrt((math.max(rgb[i][1], r) - math.min(rgb[i][1], r)) ^ 2 + (math.max(rgb[i][2], g) - math.min(rgb[i][2], g)) ^ 2 + (math.max(rgb[i][3], b) - math.min(rgb[i][3], b)) ^ 2)
    if d < dist then
      dist = d
      color = i - 1
    end
  end
  return 2 ^ color
end

print("Welcome to DiscordCC")
local cli = discordapi.Client:new()
if fs.exists("dstk") then
    print("Already logged in")
    local file = fs.open("dstk", "r")
    cli:loginWithToken(file.readAll())
    file.close()
else
    write("Enter your email: ")
    local email = read()
    write("Enter your password: ")
    if cli:login(email, read("*")) == "" then
        print("Error logging in")
        return
    end
    if cli:getToken() == nil then
        print("Error logging in")
        return
    end
    local tfile = fs.open("dstk", "w")
    tfile.write(cli:getToken())
    tfile.close()
end

function getIdFromList(list, id)
    for k,v in pairs(list) do
        if v.id == id then
            return v
        end
    end
    return nil
end

roles = {server="", roles={}}
member = {server="", members={}}

function getUserColor(server, user)
    if member.server ~= server or member.members[user] == nil then 
        --print("Getting member " .. user .. " on server " .. server)
        member.members[user] = cli:getGuildMember(server, user) 
        member.server = server
    end
    if roles.server ~= server then 
        --print("Getting roles on server " .. server)
        roles.roles = cli:getRoles(server) 
        roles.server = server
    end
    local color = colors.gray
    local highest = {position=0 }
    for k,v in pairs(member.members[user].roles) do
        local current = getIdFromList(roles.roles, v)
        if current.position > highest.position and current.hoist then
            highest = current
        end
    end
    if highest.color ~= nil then
        local blue = math.floor(highest.color / 65536);
        local green = math.floor((highest.color-(blue*65536)) / 256);
        local red = highest.color -(blue*65536) - (green*256);
        color = colors.fromRGB(red, green, blue)
    end
    return color
end

function snowflakeSort(tab)
    local last = 0
    return function()
            local closest = {id=1e100}
            local id = 0
            for k,v in ipairs(tab) do
                if tonumber(v.id) - last < tonumber(closest.id) - last and tonumber(v.id) > last then
                    closest = v
                    id = k
                end
            end
            if id == 0 or closest.id == 1e100 then return nil end
            last = tonumber(closest.id)
            return id, closest
        end
end
channel = ""
server = ""
readMessages = {}
function serverSelect()
    term.clear()
    local servers = {}
    local serverList = cli:getServerList()
    local i = 1
    print("Choose a server:")
    for k,v in pairs(serverList) do
        print(i .. ": " .. v.name)
        servers[i] = v.id
        i=i+1
    end
    write("> ")
    server = servers[tonumber(read())]
    i = 1
    print("Choose a channel:")
    local channels = {}
    local channelList = cli:getChannelList(server)
    for k,v in pairs(channelList) do
        if v.type == 0 then
            print(i .. ": " .. v.name)
            channels[i] = v.id
            i=i+1
        end
    end
    write("> ")
    channel = channels[tonumber(read())]
    readMessages = {}
end
serverSelect()
write("> ")
run = true
waiting = false
toread = false
going = false
select = false
function getMessages()
    --print("Starting msgd...")
    local first = 0
    local w, h = term.getSize()
    if not going then
        local lastmessage = {}
        while run do
            going = true
            local messages = cli:getMessages(channel)
            local messageids = {}
            for k,v in snowflakeSort(messages) do table.insert(messageids, v.id) end
            if first == 0 then
                for k,v in ipairs(messages) do 
                    --if readMessages[v.id] == true then table.remove(messages, k) end 
                    readMessages[v.id] = true
                end
                while table.getn(messages) > h do
                    table.remove(messages, 0)
                end
                for k,v in snowflakeSort(messages) do
                    --if readMessages[v.id] == nil and v.author ~= nil and v.content ~= nil then
                        --print(textutils.serialize(v))
                        if not waiting then term.scroll(1) end
                        term.setCursorPos(1, h - 1)
                        term.setTextColor(getUserColor(server, v.author.id))
                        write(v.author.username)
                        term.setTextColor(colors.gray)
                        print(": " .. v.content)
                        term.setTextColor(colors.white)
                        if first == 1 then write("> ") end 
                        readMessages[v.id] = true
                    --end
                end
            else
                for k,v in ipairs(messages) do if readMessages[v.id] == true then table.remove(messages, k) end end
                while table.getn(messages) > h do
                    table.remove(messages, 0)
                end
                for k,v in snowflakeSort(messages) do
                    if readMessages[v.id] == nil and v.author ~= nil and v.content ~= nil then
                        --print(textutils.serialize(v))
                        if not waiting then term.scroll(1) end
                        term.setCursorPos(1, h - 1)
                        term.setTextColor(getUserColor(server, v.author.id))
                        write(v.author.username)
                        term.setTextColor(colors.gray)
                        print(": " .. v.content)
                        term.setTextColor(colors.white)
                        if first == 1 then write("> ") end 
                        readMessages[v.id] = true
                    end
                end
            end
            first = 1
            going = false
            os.sleep(1)
        end
    end
    --print("Stopping msgd...")
    --coroutine.yield()
end
function sendMessages()
    sleep(1)
    local x, y = term.getCursorPos()
    term.setCursorPos(1, y)
    print("Type /server to change servers and /quit to quit.")
    write("> ")
    while true do
        --print("msgd status: " .. coroutine.status(msgd))
        --coroutine.resume(msgd)
        local msg = read()
        if msg == "/quit" then 
            run = false
            return 
        elseif msg == "/read" then
            toread = true
            return
        elseif msg == "/server" then
            select = true
            return
        elseif msg == "/logout" then
            fs.delete("dstk")
            run = false
            return
        else
            cli:sendMessage(msg, channel)
        end
        local w, h = term.getSize()
        term.setCursorPos(1, h-1)
        write("                                                  ")
        term.setCursorPos(1, h-1)
        write("> ")
        waiting = true
    end
end
function readAllMessages()
    local messages = cli:getMessages(channel)
    local lines = {}
    local w, h = term.getSize()
    local lnum = 0
    print("Sorting messages...")
    for k,v in snowflakeSort(messages) do
        local linecount = math.ceil((string.len(v.author.username) + string.len(v.content) + 2) / w)
        table.insert(lines, {type=0, user=v.author.username, color=getUserColor(server, v.author.id), message=string.sub(v.content, 1, w - string.len(v.author.username) - 2)})
        lnum = lnum + linecount
        local l = 1
        while l < linecount do
            local last = (l + 1) * w + 1 - string.len(v.author.username)
            if last > string.len(v.content) then
                last = string.len(v.content)
            end
            table.insert(lines, {type=1, message=string.sub(v.content, l * w - 1 - string.len(v.author.username), (l + 1) * w - 2 - string.len(v.author.username))})
            l=l+1
        end
    end
    print("Done sorting.")
    local i = lnum - h
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        local l = i
        while l < i + h - 1 and lines[l] ~= nil do
            if lines[l].type == 0 then
                term.setTextColor(lines[l].color)
                write(lines[l].user)
                term.setTextColor(colors.gray)
                print(": " .. lines[l].message)
                term.setTextColor(colors.white)
            else
                term.setTextColor(colors.gray)
                print(lines[l].message)
                term.setTextColor(colors.white)
            end
            l=l+1
        end
        if lines[l].type == 0 then
            term.setTextColor(lines[l].color)
            write(lines[l].user)
            term.setTextColor(colors.gray)
            write(": " .. lines[l].message)
            term.setTextColor(colors.white)
        else
            term.setTextColor(colors.gray)
            write(lines[l].message)
            term.setTextColor(colors.white)
        end
        --write(i)
        while true do
            local ev, button = os.pullEvent("key")
            if button == keys.q then
                return
            elseif button == keys.up then
                if i > 1 then i=i-1 end
                break
            elseif button == keys.down then
                if i < lnum - h then i=i+1 end
                break
            elseif button == keys.f then
                if i < lnum - (2 * h) then i=i+h end
                break
            elseif button == keys.b then
                if i > h then i=i-h end
                break
            elseif button == keys.d then
                if i < lnum - (1.5 * h) then i=i+(h/2) end
                break
            elseif button == keys.u then
                if i > h / 2 then i=i-(h/2) end
                break
            elseif button == keys.comma then
                i = 0
                break
            elseif button == keys.period then
                i = lnum - h
                break
            elseif button == keys.h then
                term.clear()
                term.setCursorPos(1, 1)
                print([[The syntax of the viewer is similar to less.
----------------------------------
h     *  Display this help.
down  *  Forward one line.
up    *  Backward one line.
f     *  Forward one screen.
b     *  Backward one screen.
d     *  Forward one half-screen.
u     *  Backward one half-screen.
,     *  Go to the first line.
.     *  Go to the last line.
----------------------------------
Press any key to close.]])
                os.pullEvent("key")
                break
            --else
                --print("Unknown key " .. button)
            end
        end
    end
end
hh = false
if not hh then
    while true do
        if not hh then
            hh = true
            parallel.waitForAny(getMessages, sendMessages)
            hh = false
            if toread == true then
                readAllMessages()
                toread = false
            elseif run == false then
                break
            elseif select == true then
                serverSelect()
                select = false
            end 
        end
    end
end
--cli:logout()
