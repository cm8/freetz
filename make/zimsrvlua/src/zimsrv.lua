#!/usr/bin/lua

require('io')

local iobs = 2^13
local up = struct and struct.unpack or require('struct').unpack

local Zim = {}

function Zim:new(fname)
    z = {}
    setmetatable(z, self)
    self.__index = self

    z.f = assert(io.open(fname, "rb"))

    z.h = {}
    z:readHeader()

    z.m = { get = function (t, i) return t[i+1] end }
    z:readMime()

    --o:printHeader()
    --o:printMime()

    local i = fname..".idx"
    z.i = assert(io.open(i, "r") or z:createIndexSimple(i) or io.open(i, "r"))

    return z
end

function Zim:readHeader()
    local f, h, uenc = self.f, self.h,
    function (u) return string.format("%02X", string.byte(u)) end

    h.magicNumber     = f:read(4)
    h.magicNumberHex  = "0x"..h.magicNumber:gsub(".", uenc)
    h.version         = up("<I", f:read(4))
    h.uuid            = "0x"..f:read(16):gsub(".", uenc)
    h.articleCount    = up("<I", f:read(4))
    h.clusterCount    = up("<I", f:read(4))
    --h.urlPtrPos       = up("<I", f:read(4))
    --h.urlPtrPos64     = up("<I", f:read(4))
    h.urlPtrPos       = up("<L", f:read(8))
    --h.titlePtrPos     = up("<I", f:read(4))
    --h.titlePtrPos64   = up("<I", f:read(4))
    h.titlePtrPos     = up("<L", f:read(8))
    --h.clusterPtrPos   = up("<I", f:read(4))
    --h.clusterPtrPos64 = up("<I", f:read(4))
    h.clusterPtrPos   = up("<L", f:read(8))
    --h.mimePtrPos      = up("<I", f:read(4))
    --h.mimePtrPos64    = up("<I", f:read(4))
    h.mimePtrPos      = up("<L", f:read(8))
    h.mainPage        = up("<I", f:read(4))
    h.layoutPage      = up("<I", f:read(4))
    --h.checksumPos     = up("<I", f:read(4))
    --h.checksumPos64   = up("<I", f:read(4))
    h.checksumPos     = up("<L", f:read(8))
end

function Zim:readMime()
    local f, h, m = self.f, self.h, self.m

    f:seek("set", h.mimePtrPos)

--  --alternative not depending on readUntilZero
--  local n, bufsz = 0, 4096
--  local buf = f:read(bufsz)
--
--  while not (n < 0)
--  do buf = buf:sub(1 + n)..f:read(bufsz)
--     n = 0
--     for s in buf:gmatch("[^%z]*%z")
--     do if #s > 1
--        then m[#m+1] = s:sub(1, -2)
--        end
--        n = n + #s
--        if #s == 1
--        then n = -n
--             break
--        end
--     end
--  end

    repeat m[#m+1] = self:readUntilZero()
    until #m[#m] == 0
end

function Zim:printHeader(t)
    local s = {}

    for k, v in pairs(t or self.h)
    do s[#s+1] = k..": "..v
    end

    table.sort(s)
    s[#s+1] = ""
    io.stderr:write(table.concat(s, "\n"))
end

function Zim:printMime(t)
    for k, v in ipairs(t or self.m)
    do io.stderr:write(k..": "..v.."\n")
    end
end

function Zim:createIndexSimple(zi)
    local c, a = self.h.articleCount

    self.i = assert(io.open(zi, "w"))
    for n = 0, c-1
    do a = self:readEntry(n)
       if a.namespace == "A"
       then self.i:write(a.url, "\n")
       else io.stderr:write("INFO: Entry in namespace ", a.namespace,
                            " excluded from index: ", a.url, "\n")
       end
    end
    self.i:close()
end

function Zim:getBlobXz(bn, cs)
    local f, x, child, rd, wr = self.f, require("posix.unistd")
    x.wait = require("posix.sys.wait").wait

    rd, wr = x.pipe()
    if rd
    then io.flush()
    else error("failed to create rd/wr pipe")
    end

    child = x.fork()
    if child ~= 0
    then x.close(wr)
    else x.close(rd)
         x.dup2(wr, x.STDOUT_FILENO)

         local p, buf = assert(io.popen("xz -d", "w"))
         while cs > 0
         do buf = f:read((iobs < cs) and iobs or cs)
            cs = cs - #buf
            while not p:write(buf)
            do x.sleep(1)
            end
         end
         p:close()

         x._exit(0)
    end

    return self:getBlobPlain(bn, {
        read = function (_, n) return x.read(rd, n) end,
        fin = function (_) x.close(rd) x.wait(child) end
    })
end

function Zim:getBlobPlain(bn, f)
    local f, pos, sz = f or self.f
    local cat = function (sz, o)
        local buf = ""
        while sz
        do sz = 0 < sz and sz - #buf or nil
           buf = sz and f:read(iobs < sz and iobs or sz)
           if o and buf
           then o:write(buf)
                o:flush()
           end
        end
        if o and f.fin
        then f:fin()
        end
    end

    --f:seek("cur", 4*bn)
    cat(4*bn)

    pos = up("<I", f:read(4))
    sz  = -pos + up("<I", f:read(4))

    --f:seek("cur", pos -4*bn -4 -4)
    cat(pos -4*bn -4 -4)

    return sz, cat --caller calls cat to output blob
end

function Zim:getBlobFromCluster(n, bn)
    local cs, cc = self:seekClusterPtr(n)

    cc = up("B", self.f:read(1))
    cs = cs - 1

    if cc == 4
    then return self:getBlobXz(bn, cs)
    else if cc == 1
         then return self:getBlobPlain(bn)
         else error(string.format("Invalid compression type %d of cluster %d", cc, n))
         end
    end
end

function Zim:seek(s, t, n, c)
    if n > c
    then error(string.format("%sNumber %d exceeds max count of %d", t, n, c))
    else return self.f:seek("set", s)
    end
end

function Zim:seekClusterPtr(n)
    local f, h = self.f, self.h
    local c, pos, sz = h.clusterCount

    if self:seek(h.clusterPtrPos + 8*n, "cluster", n, c)
    then pos = up("<L", f:read(8))
         sz  = -pos + (n < c and up("<L", f:read(8)) or h.checksumPos)
    end

    f:seek("set", pos)
    return sz, pos
end

function Zim:seekTitlePtr(n)
    local f, h = self.f, self.h
    local c, i = h.articleCount

    if self:seek(h.titlePtrPos + 4*n, "article", n, c)
    then i = up("<L", f:read(4))
    end

    -- n-th alphabetically ordered title is at i-th entry in urlPtr list
    self:seekUrlPtr(i)
end

function Zim:seekUrlPtr(n)
    local f, h = self.f, self.h
    local c, pos, sz = h.articleCount

    if self:seek(h.urlPtrPos + 8*n, "article", n, c)
    then pos = up("<L", f:read(8))
    end

    f:seek("set", pos)
end

function Zim:readUntilZero()
    local f, r, bs, x = self.f, {}, 512

    while not x
    do r[#r+1] = f:read(bs)
       if #r[#r] > 0
       then x = r[#r]:find("%z")
       else error("no more data searching for 0x00 byte")
       end
    end

    f:seek("cur", x-bs)
    r[#r] = r[#r]:sub(1, x-1)

    return #r > 1 and table.concat(r) or r[1]
end

function Zim:readEntry(n)
    local f, a = self.f, {}

    if n --if n == nil caller did seek, sets a.number
    then self:seekUrlPtr(n)
         a.number = n
    end

    a.mimetype      = up("<H", f:read(2))
    a.parameter_len = up( "B", f:read(1))
    a.namespace     = f:read(1)
    a.revision      = up("<I", f:read(4))

    if a.mimetype == 0xffff
    then a.redirect_index = up("<I", f:read(4))
    else a.cluster_number = up("<I", f:read(4))
         a.blob_number    = up("<I", f:read(4))
    end

    a.url       = self:readUntilZero()
    a.title     = self:readUntilZero()
    a.parameter = f:read(a.parameter_len)

    return a
end

function Zim:findEntryNum(url)
    local nAbove = self.h.articleCount
    local nBelow = 0
    local n, a, x

    while nAbove >= nBelow
    do n = math.floor((nAbove + nBelow) / 2);
       a = self:readEntry(n);
       x = "/"..a.namespace.."/"..a.url
       if x > url
       then nAbove = n - 1
       else if x < url
            then nBelow = n + 1
            else return n, a
            end
       end
    end
end

function Zim:findFavIconNum()
    local n, a

    for _, ns in ipairs({"/-/", "/I/"})
    do for _, v in ipairs({"", ".ico", ".png", ".jpg"})
       do n, a = self:findEntryNum(ns.."favicon"..v)
          if n
          then return n, a
          end
       end
    end
end

function Zim:findMainPageNum()
    local n, a = self.h.mainPage

    if n ~= 0xffffffff
    then return n, self:readEntry(n)
    end

    for _, w in ipairs({"index", "mainpage", "wikipedia"})
    do for _, v in ipairs({"", ".htm", ".html"})
       do for _, u in ipairs({w, w:sub(1,1):upper()..w:sub(2)})
          do n, a = self:findEntryNum("/A/"..u..v)
             if n
             then return n, a
             end
          end
       end
    end
end

function Zim:outputArticleOrEntry(n, a, o)
    a = a or n and self:readEntry(n)

    if not a
    then return
    end

    while a.redirect_index
    do n = a.redirect_index
       a = self:readEntry(n)
    end

    local sz, w = self:getBlobFromCluster(a.cluster_number, a.blob_number)
    o:write(
      "HTTP/1.1 200 OK\n",
      "Content-Type: ", self.m:get(a.mimetype), "\n",
      "Content-Length: ", sz, "\n\n"
    )
    w(sz, o)

    return a
end

function Zim:searchHelp()
    local r = {
      { "<u>Search help:</u>", "" },
      { "str", "equivalent to (*) below" },
      { "^str", "prefix %s at start" },
      { "str$", "suffix %s at end" },
      { "^^str", "(*) word prefix %s at begin of %s" },
      { "str$$", "word suffix %s at end of %s" },
      { "^^str$$", "word %s matching %s" },
      { "", "<i>search is case-insensitive</i>" },
      u = '<tr><td style="text-align:right"><b>%s</b></td><td>%s</td></tr>',
      v = 'search, match article titles with <b>str</b>',
      w = 'at least one word in title'
    }

    for i, v in ipairs(r)
    do r[i] = r.u:format(v[1], v[2]:format(r.v, r.w))
    end
    r[1] = '<table style="border:none;border-spacing:10px">\n'..r[1]
    r[#r+1] = '</table>'

    return r
end

function Zim:outputSearch(q, o)
    if q:match("^/[AQq][=/]")
    then q = q:sub(4):gsub("^%?q=", "")
    else return
    end

    local r, a, m, p = {}, '<a href="/%s">%s</a><br/>', #q > 2 and 1000,
    q:gsub("^[^^].*[^$]$", "^^%0"):gsub("%w",
      function (u) return ("[%s%s]"):format(u:lower(), u:upper()) end
    ):gsub("^%^%^(.*)", "%%f[%%w]%1"):gsub("(.*)%$%$$", "%1%%f[^%%w]")

    if m
    then for l in self.i:lines()
         do if #r < m
            then r[#r+1] = l:match(p) and a:format(l, l:gsub("_", " "))
            else break
            end
         end
         self.i:seek("set", 0)
         m = ("returned %d results%s"):format(#r, #r < m and ""
           or ", the result limit. Please use a search term more specific")
    else m = "skipped, because length < 3"
    end
    m = ("<p>Search for '%s' %s.</p>"):format(q:gsub("[$^]", ""), m)

    if #r == 0
    then r = self:searchHelp()
    end
    r[1] = "<!DOCTYPE html><html><body>"..m..r[1]
    r[#r+1] = '<br/><form action="/Q/">'
    r[#r+1] = '<input type="text" name="q" value="'..q..'">'
    r[#r+1] = '<input type="submit" value="New search"></form>'
    r[#r+1] = "</body></html>"

    r = table.concat(r, "\n")
    o:write(
      "HTTP/1.1 200 OK\n",
      "Content-Type: text/html; charset=utf-8\n",
      "Content-Length: ", #r, "\n\n", r
    )
end

function main()
    local z = Zim:new(
      arg[1] or require('os') and os.getenv("ZIM_FILE") or arg[0]..".zim"
    )

    --local n, a = z:findEntryNum("/A/MyArticleTitle")
    --if n
    --then z:printHeader(a)
    --     z:outputArticleOrEntry(n, a) --only n mandatory
    --end

    local q, udec, oA, oS = (
      arg[2] or require('os') and os.getenv("QUERY_STRING") or "/"
    ),
    function (u)    return string.char(tonumber("0x"..u:sub(2))) end,
    function (n, a) return z:outputArticleOrEntry(n, a, io.stdout) end,
    function (q)    return z:outputSearch(q, io.stdout) end

    q = q:gsub("%%..", udec)

    if q:match("^/?$")
    then oA(z:findMainPageNum())
    else if q:match("^/favicon")
         then oA(z:findFavIconNum())
         else if q:match("^/[Qq][=/]")
              then oS(q)
              else q = q:match("^/[-A-Z]/") and q or "/A"..q
                   q = oA(z:findEntryNum(q)) or oS(q)
              end
         end
    end
end

main()
