local inFile, outFile = ...
if not inFile or not outFile then
  io.stderr:write('Usage: lua obfuscator.lua <in> <out>\n')
  os.exit(1)
end

-- compile input file
local chunk = assert(loadfile(inFile))
local dumped = string.dump(chunk)

-- generate random key for XOR
math.randomseed(os.time())
local key = {}
for i = 1, 32 do
  key[i] = string.char(math.random(33,126))
end
key = table.concat(key)

-- simple XOR helper using bitwise ops
local function bxor(a, b)
  local res = 0
  for i = 0,7 do
    local x = a % 2 + b % 2
    if x == 1 then res = res + 2^i end
    a = (a - a % 2) / 2
    b = (b - b % 2) / 2
  end
  return res
end

local function xor(data, k)
  local out = {}
  for i=1,#data do
    local kb = k:byte(((i-1)%#k)+1)
    out[i] = string.char(bxor(data:byte(i), kb))
  end
  return table.concat(out)
end

local protected = xor(dumped, key)

-- base64 encode
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function enc(data)
  return ((data:gsub('.',function(x)
    local r,b='',x:byte()
    for i=8,1,-1 do r=r..((b%2^i-b%2^(i-1)>0) and '1' or '0') end
    return r
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?',function(x)
    if(#x<6)then return '' end
    local c=0
    for i=1,6 do c=c+((x:sub(i,i)=='1') and 2^(6-i) or 0) end
    return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
end

local encoded = enc(protected):reverse()

-- write obfuscated lua script
local out = assert(io.open(outFile,'w'))
out:write(string.format([[local key=%q
local b=%q
local function dec(data)
 data=data:gsub('[^'..b..'=]','')
 return (data:gsub('.',function(x)
  if(x=='=')then return'' end
  local r,f='',(b:find(x)-1)
  for i=6,1,-1 do r=r..((f%2^i-f%2^(i-1)>0) and '1' or '0') end
  return r
 end):gsub('%d%d%d?%d?%d?%d?%d?%d?',function(x)
  if(#x~=8)then return'' end
  local c=0
  for i=1,8 do c=c+((x:sub(i,i)=='1') and 2^(8-i) or 0) end
  return string.char(c)
 end))
end
local function bxor(a,b)
 local r=0
 for i=0,7 do
  local x=a%2+b%2
  if x==1 then r=r+2^i end
  a=(a-a%2)/2 b=(b-b%2)/2
 end
 return r
end
local function xor(data,k)
 local t={}
 for i=1,#data do
  local kb=k:byte(((i-1)%#k)+1)
  t[i]=string.char(bxor(data:byte(i),kb))
 end
 return table.concat(t)
end
local chunk=assert(load(xor(dec(string.reverse(%q)),key)))
chunk(...)
]], key, b, encoded))
out:close()
