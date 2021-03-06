MULTIS = {}

local function down (T, i, sup, ret)
    local t = T[i]
    local dyn = unpack(T[i])
    local up = ret[#ret]
    for _, dcl in ipairs(sup.hier.down) do
        local me = {
            data = 'CEU_DATA_'..TYPES.noc(dcl.id),
            dyn  = string.gsub(t.dyn, '_'..t.base.id_,
                                      '_'..TYPES.noc(dcl.id_)),
            id   = dcl.id,

            idx  = #ret+1,
            left = ret,
            up   = up,
        }
        ret[#ret+1] = me
        down(T, i, dcl, ret)
        fff(T, i+1, me)
    end
end

function fff (T , i, ret)
    if i > #T then
        return
    end
    assert(#ret == 0)

    local t = T[i]
    local me = {
        data = 'CEU_DATA_'..TYPES.noc(t.base.id),
        dyn  = t.dyn,
        id   = t.base.id,

        idx  = #ret+1,
        left = ret,
        up   = nil,
    }
    ret[#ret+1] = me
    down(T, i, t.base, ret)
    fff(T, i+1, me)
end

--[[
function dump (ret, spc)
    spc = spc or ''
    if #ret == 0 then
        local dyn = ret.dyn
        while ret.left.dyn do
            dyn = ret.left.dyn..dyn
            ret = ret.left
        end
        local has = DCLS.get(AST.par(AST.iter()(),'Block'), dyn)
        print(spc..dyn)
        print(spc..'('..tostring(has)..')')
    else
        for i, t in ipairs(ret) do
            local spc = spc..'  '
            --print(spc..'{ id='..t.id..',')
            print(spc..'['..i..'] = { data='..t.data..', id='..t.id..
                                    ', up='..(t.up and t.up.id or '')..
                                    ', left='..(t.left.id or '')..',')
            dump(t, spc..' ')
            print(spc..'}')
        end
    end
end
]]

function get (Code, ret, goleft)
    local dyn = ret.dyn
    local cur = ret
    while cur.left.dyn do
        dyn = cur.left.dyn..dyn
        cur = cur.left
    end
    dyn = Code.id..dyn

    local dcl = DCLS.get(AST.par(Code,'Block'), dyn)
    if dcl then
        return dcl
    end

    if ret.up then
        dcl = get(Code, ret.up, false)
        if dcl then
            return dcl
        end
    end

    if goleft then
        local idxs = { ret.idx }
        local left = assert(ret.left)
        while not left.up do
            left = ASR(left.left, Code, 'missing implementation')
            idxs[#idxs+1] = 1
        end
        local t = left.up
        for i=#idxs,1,-1 do
            t = t[ idxs[i] ]
        end
        dcl = get(Code, t, true)
        return assert(dcl)
    end
end

--[[
function dump2 (Code, ret, spc)
    spc = spc or ''
    if #ret == 0 then
        return (spc..get(Code,ret,true).id)..'\n'
    else
        local str = ''
        for i, t in ipairs(ret) do
            local spc = spc..'  '
            --print(spc..'{ id='..t.id..',')
            str = str .. (spc..'['..i..'] = { data='..t.data..', id='..t.id..
                            --', me='..string.sub(tostring(t),8)..
                            --', left='..string.sub(tostring(t),8)..
                            ', up='..(t.up and t.up.id or '')..
                            ', left='..(t.left.id or '')..',') .. '\n'
            str = str .. dump2(Code, t, spc..' ')
            str = str .. (spc..'}') .. '\n'
        end
        return str
    end
end
]]

function dump3 (Code, f, ret, spc)
    spc = spc or ''
    if #ret == 0 then
        return spc..f(get(Code,ret,true).id_)..',\n'
    else
        local str = ''
        for i, t in ipairs(ret) do
            local spc = spc..' '
            if #t > 0 then
                str = str..spc..'{\n'..dump3(Code,f,t,spc..' ')..spc..'},\n'
            else
                str = str..dump3(Code,f,t,spc)
            end
        end
        return str
    end
end

function dims (ret)
    if #ret > 0 then
        return '['..#ret..']'..dims(ret[1])
    else
        return ''
    end
end

local f1 = function (id)
    return 'CEU_LABEL_Code_'..id
end
local f2 = function (id)
    return 'offsetof(tceu_code_mem_'..id..', _params)'
end

function MULTIS.tostring (Code, T)
    local ret = {}
    fff(T, 1, ret)
    return dims(ret), dump3(Code,f1,ret), dump3(Code,f2,ret)
end
