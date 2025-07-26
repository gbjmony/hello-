-- 获取当前目录下的所有 .txt 文件并重命名为 .lua

local ffi = require("ffi")

-- 使用 C 库进行文件操作
ffi.cdef[[
    int system(const char *command);
    int rename(const char *oldname, const char *newname);
]]

-- 获取当前目录的文件列表（使用 Lua 的 io.popen 配合 shell 命令）
local function list_files()
    local files = {}
    local handle = io.popen("ls *.txt 2>/dev/null || dir *.txt /b 2>nul", "r")  -- 兼容 Linux/macOS 和 Windows
    if handle then
        for filename in handle:lines() do
            table.insert(files, filename)
        end
        handle:close()
    end
    return files
end

-- 主逻辑
local count = 0
for _, filename in ipairs(list_files()) do
    -- 构造新文件名：替换 .txt 为 .lua
    local newname = filename:gsub("%.txt$", ".lua", 1)
    
    -- 检查目标文件是否已存在
    if not ffi.C.rename(newname, newname) == 0 then  -- 简单判断文件是否存在
        local f = io.open(newname, "r")
        if f then
            f:close()
            print(("跳过: %s 已存在"):format(newname))
            goto continue
        end
    end

    -- 重命名
    local success = ffi.C.rename(filename, newname) == 0
    if success then
        print(("已重命名: %s -> %s"):format(filename, newname))
        count = count + 1
    else
        print(("重命名失败: %s"):format(filename))
    end

    ::continue::
end

print(("完成！共重命名 %d 个文件。"):format(count))
