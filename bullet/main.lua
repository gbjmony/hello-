-- main.lua
local game = {
    bullets = {},           -- 存储发射的字符子弹
    enemies = {},           -- 存储敌方概念
    turrets = {},           -- 我方炮台
    player_bullets = {},    -- 玩家子弹 (包括普通子弹、散弹)
    laser_beams = {},       -- 激光束
    missiles = {},          -- 导弹
    explosions = {},        -- 爆炸效果 (包括导弹和核弹)
    current_clip = {},      -- 当前弹夹
    clip_index = 1,         -- 当前弹夹索引
    text_files = {},        -- 文本文件列表
    file_index = 1,         -- 当前文件索引
    player_x = 400,         -- 玩家位置
    player_y = 500,
    player_speed = 200,     -- 玩家移动速度
    bullet_speed = 250,     -- 子弹速度
    -- enemy_speed = 80,       -- 基础敌人移动速度 (移入 enemy_types)
    fire_rate = 0.05,       -- 玩家发射频率
    last_fire = 0,          -- 玩家上次发射时间
    last_enemy = 0,         -- 上次生成敌人时间
    -- 大幅增加敌人密度
    enemy_rate = 0.0001,      -- 敌人生成频率（秒）- 极高密度 (从 0.05 降低到 0.01)
    font = nil,
    score = 0,
    bullets_dir = "bullets", -- 子弹文件目录
    can_fire = true,         -- 是否可以发射子弹/散弹
    can_laser = true,        -- 是否可以发射激光
    can_missile = true,      -- 是否可以发射导弹 (玩家)
    can_nuke = true,         -- 是否可以发射核弹 (玩家)
    laser_cooldown = 0,      -- 玩家激光冷却时间
    missile_cooldown = 0,    -- 玩家导弹冷却时间
    nuke_cooldown = 0,       -- 玩家核弹冷却时间
    laser_cost = 10,         -- 激光消耗子弹数
    missile_cost = 3,        -- 导弹消耗子弹数
    nuke_cost = 50,          -- 核弹消耗子弹数
    -- enemy_concepts = {...}, -- 移入 enemy_types
    turret_types = {         -- 炮台类型
        "标准炮", "散弹炮", "激光炮", "追踪炮", "导弹炮" -- 添加导弹炮
    },
    -- 导弹相关配置
    missile_speed = 150,       -- 导弹速度
    missile_blast_radius = 50, -- 爆炸半径
    missile_damage = 2,        -- 爆炸伤害
    missile_cooldown_time = 2.0, -- 玩家/炮台导弹冷却时间
    -- 核弹相关配置
    nuke_cooldown_time = 30.0,   -- 核弹冷却时间
    nuke_blast_radius = 300,     -- 核弹爆炸半径
    -- 爆炸效果
    explosion_duration = 0.3,    -- 普通爆炸效果持续时间
    -- 升级系统
    current_level = 1,           -- 当前等级
    next_level_score = 100,      -- 下一级所需分数 (初始100分)
    level_upgrades = {           -- 每级升级效果 (相对于基础值)
        -- [等级] = {射速倍增, 伤害倍增, ... 其他属性}
        [1] = { fire_rate_mult = 1.0, damage_mult = 1.0 }, -- 基础等级
        [2] = { fire_rate_mult = 1.2, damage_mult = 1.1 },
        [3] = { fire_rate_mult = 1.4, damage_mult = 1.2 },
        [4] = { fire_rate_mult = 1.6, damage_mult = 1.3 },
        [5] = { fire_rate_mult = 1.8, damage_mult = 1.5 },
        [6] = { fire_rate_mult = 2.0, damage_mult = 1.7 },
        [7] = { fire_rate_mult = 2.2, damage_mult = 2.0 },
        [8] = { fire_rate_mult = 2.5, damage_mult = 2.3 },
        [9] = { fire_rate_mult = 2.8, damage_mult = 2.6 },
        [10] = { fire_rate_mult = 3.0, damage_mult = 3.0 }, -- 满级
    },
    -- 不同敌人类型定义
    enemy_types = {
        -- 基础敌人
        ["基础"] = {
            health = 1,
            speed_range = {60, 100}, -- 随机速度范围
            width = 20,
            height = 20,
            color = {1, 0, 0}, -- 红色
            concept_list = {"教", "义", "欲", "贪", "嫉", "怒", "懒", "傲", "偏", "迷"}
        },
        -- 坚硬敌人
        ["坚硬"] = {
            health = 3,
            speed_range = {40, 70},
            width = 25,
            height = 25,
            color = {0.7, 0, 0.7}, -- 紫色
            concept_list = {"冷", "私", "欺", "背", "恨"}
        },
        -- 快速敌人
        ["快速"] = {
            health = 1,
            speed_range = {120, 180},
            width = 15,
            height = 15,
            color = {1, 0.5, 0}, -- 橙色
            concept_list = {"恐", "焦", "绝", "无", "愚"}
        }
        -- 可以继续添加更多类型...
    },
    -- 调试参数 - 你可以修改这些值来测试炮管方向
    debug_player_angle = -math.pi/2,    -- 玩家炮管角度（弧度）
    debug_turret_angle = -math.pi/2,    -- 炮台炮管角度（弧度）
    show_debug_info = true              -- 是否显示调试信息
}
-- 创建我方炮台（调整类型概率、射速、分布，加入导弹炮）
function game:createTurrets()
    local turret_y = 550  -- 炮台Y位置
    local num_turrets = 28 -- 炮台总数
    -- 计算居中分布的参数
    local total_width = (num_turrets - 1) * 25 -- 27 gaps of 25px
    local start_x = (800 - total_width) / 2 -- 屏幕宽度800

    for i = 1, num_turrets do
        local turret_type
        local rand = math.random(1, 100)
        -- 调整炮台类型概率，降低高火力炮台，加入导弹炮
        if rand <= 55 then
            turret_type = "标准炮"   -- 55%
        elseif rand <= 80 then
            turret_type = "散弹炮"   -- 25%
        elseif rand <= 90 then
            turret_type = "激光炮"   -- 10%
        elseif rand <= 95 then
            turret_type = "追踪炮"   -- 5%
        else
            turret_type = "导弹炮"   -- 5%
        end

        local turret = {
            id = i,
            type = turret_type,
            -- 使用居中计算的 x 坐标
            x = start_x + (i - 1) * 25,  -- 水平居中分布
            y = turret_y,
            width = 20,
            height = 15,
            barrel_length = 18,      -- 炮管长度
            angle = game.debug_turret_angle,  -- 初始化角度
            last_shot = 0,
            -- 使用基础射击频率，升级时会调整
            base_fire_rate = 0.5, -- 基础射速 (秒/发) - 比之前慢，靠升级提升
            fire_rate = 0.5,      -- 当前射速
            energy = 100,
            -- 为导弹炮台添加独立冷却
            missile_cooldown = 0,
            -- 升级相关属性
            base_damage = 1, -- 基础伤害
            damage = 1       -- 当前伤害
        }
        -- 如果是导弹炮，初始化其冷却时间
        if turret_type == "导弹炮" then
            turret.missile_cooldown = game.missile_cooldown_time
        end
        table.insert(game.turrets, turret)
    end
    print("已创建 " .. #game.turrets .. " 门炮台 (已调整火力、密度、居中，含导弹炮)")
end
-- 获取子弹目录下的所有.lua文件
function game:getBulletFiles()
    local files = {}
    local success, items = pcall(function()
        return love.filesystem.getDirectoryItems(game.bullets_dir)
    end)
    if success and items then
        for i, filename in ipairs(items) do
            if string.match(filename, "%.txt$") or string.match(filename, "%.lua$") then
                local full_path = game.bullets_dir .. "/" .. filename
                table.insert(files, full_path)
                print("发现子弹文件: " .. full_path)
            end
        end
    else
        print("无法访问子弹目录或目录为空")
    end
    return files
end
-- 从文件读取文本内容
function game:loadTextFromFile(filepath)
    print("尝试读取文件: " .. filepath)
    local content = love.filesystem.read(filepath)
    if content then
        print("成功读取文件: " .. filepath .. " (大小: " .. #content .. " 字符)")
        return content
    else
        print("无法读取文件: " .. filepath)
        return ""
    end
end
-- 将文本内容分解为单个字符
function game:parseTextToCharacters(text)
    local characters = {}
    for i = 1, #text do
        local char = string.sub(text, i, i)
        if char ~= "\n" and char ~= "\r" and char ~= "\t" then
            table.insert(characters, char)
        end
    end
    return characters
end
-- 加载弹夹
function game:loadClip()
    if #self.text_files == 0 then
        print("没有找到子弹文件")
        return false
    end
    if self.file_index > #self.text_files then
        self.file_index = 1
        print("循环回到第一个文件")
    end
    local filepath = self.text_files[self.file_index]
    local text_content = self:loadTextFromFile(filepath)
    if text_content and #text_content > 0 then
        self.current_clip = self:parseTextToCharacters(text_content)
        self.clip_index = 1
        print("已加载弹夹: " .. filepath .. " (包含 " .. #self.current_clip .. " 个字符)")
        return true
    else
        print("文件为空或读取失败: " .. filepath)
        self.file_index = self.file_index + 1
        return self:loadClip()
    end
end
-- 消耗子弹（所有武器共用同一弹夹）
function game:consumeBullet(count)
    count = count or 1
    if (#self.current_clip - self.clip_index + 1) >= count then
        self.clip_index = self.clip_index + count
        return true
    else
        -- 子弹不足，尝试切换文件
        print("子弹不足，切换文件")
        self.file_index = self.file_index + 1
        if self:loadClip() then
            return self:consumeBullet(count)
        else
            return false
        end
    end
end
-- 计算炮管末端位置
function game:getBarrelEnd(x, y, angle, barrel_length)
    return x + math.cos(angle) * barrel_length,
           y + math.sin(angle) * barrel_length
end
-- 发射普通子弹（确保从炮管口发射，瞄准敌人）
function game:fireBullet(x, y, angle, target_x, target_y, is_player, damage_multiplier)
    damage_multiplier = damage_multiplier or 1
    if not self:consumeBullet(1) then
        return false
    end
    local char_index = self.clip_index - 2  -- 因为已经消耗了子弹
    if char_index < 1 then
        char_index = #self.current_clip
    end
    local char = self.current_clip[char_index]
    -- 计算精确方向向量
    local dx, dy
    if target_x and target_y then
        dx = target_x - x
        dy = target_y - y
        local length = math.sqrt(dx*dx + dy*dy)
        if length > 0 then
            dx = dx / length
            dy = dy / length
        end
    else
        -- 使用炮管角度
        dx = math.cos(angle)
        dy = math.sin(angle)
    end
    local bullet = {
        char = char,
        x = x,
        y = y,
        vx = dx * self.bullet_speed,
        vy = dy * self.bullet_speed,
        width = 12,
        height = 12,
        is_player = is_player or false,
        life = 3,  -- 存活时间
        damage = 1 * damage_multiplier -- 应用伤害倍增
    }
    table.insert(self.player_bullets, bullet) -- 使用 player_bullets 列表
    if not is_player then
        self.score = self.score + 1
    end
    return true
end
-- 发射散弹（从炮管口发射，基于炮管角度）
function game:fireSpreadShot(x, y, angle, damage_multiplier)
    damage_multiplier = damage_multiplier or 1
    if not self:consumeBullet(5) then  -- 散弹消耗5发子弹
        return false
    end
    for i = 1, 5 do
        local spread_angle = angle + (i - 3) * 0.25  -- 更宽的散射角度
        local char_index = self.clip_index - 1 - i
        if char_index < 1 then
            char_index = #self.current_clip + char_index
        end
        local char = self.current_clip[char_index]
        local dx = math.cos(spread_angle)
        local dy = math.sin(spread_angle)
        local bullet = {
            char = char,
            x = x,
            y = y,
            vx = dx * self.bullet_speed,
            vy = dy * self.bullet_speed,
            width = 10,
            height = 10,
            is_player = false,
            life = 2,
            damage = 1 * damage_multiplier -- 应用伤害倍增
        }
        table.insert(self.player_bullets, bullet) -- 使用 player_bullets 列表
    end
    self.score = self.score + 5
    return true
end
-- 发射激光（从炮管口发射，基于炮管角度）
function game:fireLaser(x, y, angle, damage_multiplier)
    damage_multiplier = damage_multiplier or 1
    if not self:consumeBullet(self.laser_cost) then
        return false
    end
    local dx = math.cos(angle)
    local dy = math.sin(angle)
    local laser = {
        x = x,
        y = y,
        dx = dx,
        dy = dy,
        width = 4,
        length = 600,  -- 激光长度
        duration = 0.5,  -- 持续时间
        damage = 3 * damage_multiplier  -- 应用伤害倍增
    }
    table.insert(self.laser_beams, laser)
    self.score = self.score + self.laser_cost
    return true
end
-- 发射导弹
function game:fireMissile(x, y, target_x, target_y, is_player, damage_multiplier)
    damage_multiplier = damage_multiplier or 1
    if not self:consumeBullet(self.missile_cost) then
        return false
    end

    local dx, dy = 0, -1 -- 默认向上
    if target_x and target_y then
        dx = target_x - x
        dy = target_y - y
        local length = math.sqrt(dx*dx + dy*dy)
        if length > 0 then
            dx = dx / length
            dy = dy / length
        end
    end

    -- 获取字符 (使用最后一颗消耗的子弹字符)
    local char_index = self.clip_index - 1
    if char_index < 1 then char_index = #self.current_clip end
    local char = self.current_clip[char_index]

    local missile = {
        char = char,
        x = x,
        y = y,
        vx = dx * self.missile_speed,
        vy = dy * self.missile_speed,
        width = 8,
        height = 8,
        is_player = is_player or false,
        target_x = target_x, -- 用于追踪逻辑
        target_y = target_y,
        life = 5.0, -- 5秒后消失
        damage = self.missile_damage * damage_multiplier -- 应用伤害倍增
    }
    table.insert(self.missiles, missile)

    if not is_player then
        self.score = self.score + self.missile_cost -- 发射导弹也加分
    end
    return true
end
-- 处理导弹爆炸
function game:triggerMissileExplosion(missile)
    local explosion = {
        x = missile.x,
        y = missile.y,
        radius = self.missile_blast_radius,
        duration = self.explosion_duration,
        damage = missile.damage or self.missile_damage -- 使用导弹的伤害值
    }
    table.insert(self.explosions, explosion)

    -- 对范围内的敌人造成伤害
    for j = #self.enemies, 1, -1 do
        local enemy = self.enemies[j]
        -- 计算敌人中心到爆炸中心的距离
        local distance = math.sqrt((enemy.x + enemy.width/2 - explosion.x)^2 + (enemy.y + enemy.height/2 - explosion.y)^2)
        if distance <= explosion.radius then
             -- 应用爆炸伤害
            enemy.health = enemy.health - explosion.damage
            if enemy.health <= 0 then
                table.remove(self.enemies, j)
                self.score = self.score + 5 * (enemy.max_health or 1) -- 根据敌人血量加分
            end
        end
    end
end
-- 触发核弹爆炸
function game:triggerNuke()
    if not self.can_nuke or self.nuke_cooldown > 0 then
        return false
    end

    if not self:consumeBullet(self.nuke_cost) then
        print("子弹不足，无法发射核弹")
        return false
    end

    print("核弹发射！")

    -- 创建一个全屏的爆炸效果
    local explosion = {
        x = 400, -- 屏幕中心
        y = 300,
        radius = 5, -- 初始半径很小
        max_radius = self.nuke_blast_radius,
        duration = 1.0, -- 爆炸效果持续1秒
        is_nuke = true, -- 标记为核弹爆炸
        damage = 100 -- 核弹伤害 (足够杀死所有敌人)
    }
    table.insert(self.explosions, explosion) -- 复用已有的 explosions 表

    -- 设置冷却时间
    self.nuke_cooldown = self.nuke_cooldown_time
    self.can_nuke = false

    -- 核弹加分
    self.score = self.score + self.nuke_cost

    return true
end
-- 创建敌人概念（极小且密集，不同类型）
function game:createEnemy()
    -- 决定敌人类型
    local enemy_type_name = "基础" -- 默认类型
    local rand_type = math.random(1, 100)
    if rand_type <= 70 then
        enemy_type_name = "基础" -- 70% 概率
    elseif rand_type <= 90 then
        enemy_type_name = "坚硬" -- 20% 概率
    else
        enemy_type_name = "快速" -- 10% 概率
    end

    local enemy_type_data = game.enemy_types[enemy_type_name]

    -- 从类型数据中随机选择一个概念
    local enemy_concept = enemy_type_data.concept_list[math.random(1, #enemy_type_data.concept_list)]

    local enemy = {
        id = #game.enemies + 1, -- 给敌人一个唯一ID
        type_name = enemy_type_name,
        concept = enemy_concept,
        x = math.random(10, 790),  -- 全屏随机生成
        y = -enemy_type_data.height, -- 从屏幕顶部外开始
        width = enemy_type_data.width,
        height = enemy_type_data.height,
        speed = math.random(enemy_type_data.speed_range[1], enemy_type_data.speed_range[2]),
        health = enemy_type_data.health,
        max_health = enemy_type_data.health, -- 记录最大血量，用于绘制血条和加分
        color = enemy_type_data.color
        -- 可以添加更多属性，如 immunity_flags 等
    }
    table.insert(game.enemies, enemy)
end
-- 寻找最优敌人目标（强化AI逻辑）
-- 考虑因素：距离、血量、速度、威胁度（Y坐标）
function game:findBestTargetForTurret(turret)
    local best_target = nil
    local best_score = -99999

    for _, enemy in ipairs(game.enemies) do
        local dx = enemy.x - turret.x
        local dy = enemy.y - turret.y
        local distance = math.sqrt(dx*dx + dy*dy)

        -- 如果敌人在有效射程内
        if distance < 800 then
            -- 计算优先级分数
            -- 距离越近分数越高 (负值)
            local distance_score = -distance / 100
            -- 血量越高分数越高
            local health_score = enemy.health * 2
            -- 速度越快分数越高
            local speed_score = enemy.speed / 50
            -- 越接近底部（Y值越大）分数越高 (威胁度)
            local threat_score = enemy.y / 100

            local total_score = distance_score + health_score + speed_score + threat_score

            -- 如果这个敌人分数更高，或者当前没有目标，则选择它
            if total_score > best_score or not best_target then
                best_score = total_score
                best_target = enemy
            end
        end
    end

    return best_target
end
-- 检查并处理升级
function game:checkAndApplyUpgrade()
    if self.score >= self.next_level_score and self.current_level < #self.level_upgrades then
        self.current_level = self.current_level + 1
        local upgrade = self.level_upgrades[self.current_level]
        print("升级到 " .. self.current_level .. " 级!")

        -- 应用升级到所有炮台
        for _, turret in ipairs(self.turrets) do
            -- 更新射速 (fire_rate 值越小越快)
            turret.fire_rate = turret.base_fire_rate / upgrade.fire_rate_mult
            -- 更新伤害 (如果炮台有基础伤害概念，这里可以应用)
            -- turret.damage = turret.base_damage * upgrade.damage_mult
            -- 可以在这里添加其他属性的升级，如能量恢复速度等
        end

        -- 设置下一个升级分数 (简单线性增长)
        self.next_level_score = self.next_level_score + 100 * self.current_level

        print("下一级 (" .. (self.current_level + 1) .. ") 需要 " .. self.next_level_score .. " 分")
    end
end
-- 安全的文本显示函数
function game:safePrint(text, x, y)
    local success, err = pcall(function()
        love.graphics.print(text, x, y)
    end)
    if not success then
        love.graphics.print("?", x, y)
    end
end
-- 初始化游戏
function love.load()
    print("=== 丧尸概念入侵系统启动 ===")
    game.font = love.graphics.newFont(9)
    love.graphics.setFont(game.font)
    game.text_files = game:getBulletFiles()
    if #game.text_files > 0 then
        print("找到 " .. #game.text_files .. " 个子弹文件:")
        for i, filepath in ipairs(game.text_files) do
            print("  " .. i .. ". " .. filepath)
        end
        if not game:loadClip() then
            print("无法加载任何子弹文件")
            game.current_clip = {'正', '义', '真', '理', '善', '良', '勇', '敢', '智', '慧', '爱', '和', '平', '自', '由'}
            game.clip_index = 1
            print("使用示例弹夹")
        end
    else
        print("警告: 没有在 '" .. game.bullets_dir .. "' 目录中找到文件")
        game.current_clip = {'正', '义', '真', '理', '善', '良', '勇', '敢', '智', '慧', '爱', '和', '平', '自', '由'}
        game.clip_index = 1
        print("使用示例弹夹")
    end
    game:createTurrets()
    print("========================")
end
-- 更新游戏逻辑
function love.update(dt)
    -- 检查升级
    game:checkAndApplyUpgrade()

    -- 玩家移动控制
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        game.player_x = math.max(20, game.player_x - game.player_speed * dt)
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        game.player_x = math.min(780, game.player_x + game.player_speed * dt)
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        game.player_y = math.max(300, game.player_y - game.player_speed * dt)
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        game.player_y = math.min(550, game.player_y + game.player_speed * dt)
    end
    -- 玩家瞄准（自动瞄准最近敌人）
    local player_target = nil
    local min_player_distance = 99999
    for _, enemy in ipairs(game.enemies) do
        local distance = math.sqrt((enemy.x - game.player_x)^2 + (enemy.y - game.player_y)^2)
        if distance < min_player_distance then
            min_player_distance = distance
            player_target = enemy
        end
    end
    if player_target then
        local dx = player_target.x - game.player_x
        local dy = player_target.y - game.player_y
        game.player_angle = math.atan2(dy, dx)
    else
        -- 无目标时使用调试角度
        game.player_angle = game.debug_player_angle
    end
    -- 玩家攻击
    if love.keyboard.isDown("space") and game.can_fire then
        local barrel_x, barrel_y = game:getBarrelEnd(game.player_x, game.player_y, game.player_angle, 15)
        local damage_mult = game.level_upgrades[game.current_level].damage_mult or 1
        if player_target then
            game:fireBullet(barrel_x, barrel_y, game.player_angle, player_target.x, player_target.y, true, damage_mult)
        else
            game:fireBullet(barrel_x, barrel_y, game.player_angle, nil, nil, true, damage_mult)
        end
        game.can_fire = false
    end
    if love.keyboard.isDown("x") and game.can_fire then
        local barrel_x, barrel_y = game:getBarrelEnd(game.player_x, game.player_y, game.player_angle, 15)
        local damage_mult = game.level_upgrades[game.current_level].damage_mult or 1
        game:fireSpreadShot(barrel_x, barrel_y, game.player_angle, damage_mult)
        game.can_fire = false
    end
    if love.keyboard.isDown("c") and game.can_laser and game.laser_cooldown <= 0 then
        local barrel_x, barrel_y = game:getBarrelEnd(game.player_x, game.player_y, game.player_angle, 15)
        local damage_mult = game.level_upgrades[game.current_level].damage_mult or 1
        game:fireLaser(barrel_x, barrel_y, game.player_angle, damage_mult)
        game.laser_cooldown = 1.0  -- 1秒冷却
        game.can_laser = false
    end
    -- 玩家发射导弹 (使用 'z' 键)
    if love.keyboard.isDown("z") and game.can_missile and game.missile_cooldown <= 0 then
        local barrel_x, barrel_y = game:getBarrelEnd(game.player_x, game.player_y, game.player_angle, 15)
        local damage_mult = game.level_upgrades[game.current_level].damage_mult or 1
        if player_target then
            game:fireMissile(barrel_x, barrel_y, player_target.x, player_target.y, true, damage_mult)
        else
            -- 无目标时，沿炮管方向发射
            local tx, ty = game:getBarrelEnd(barrel_x, barrel_y, game.player_angle, 100) -- 假定100像素外为目标点
            game:fireMissile(barrel_x, barrel_y, tx, ty, true, damage_mult)
        end
        game.missile_cooldown = game.missile_cooldown_time -- 设置玩家导弹冷却
        game.can_missile = false
    end
    -- 玩家发射核弹 (使用 'v' 键)
    if love.keyboard.isDown("v") then
        game:triggerNuke()
    end

    -- 重置玩家发射标志
    if not love.keyboard.isDown("space") and not love.keyboard.isDown("x") then
        game.can_fire = true
    end
    if not love.keyboard.isDown("c") then
        game.can_laser = true
    end
    if not love.keyboard.isDown("z") then
        game.can_missile = true
    end
    -- 冷却时间更新
    if game.laser_cooldown > 0 then
        game.laser_cooldown = game.laser_cooldown - dt
    end
    if game.missile_cooldown > 0 then
        game.missile_cooldown = game.missile_cooldown - dt
    end
    if game.nuke_cooldown > 0 then
        game.nuke_cooldown = game.nuke_cooldown - dt
        if game.nuke_cooldown <= 0 then
             game.nuke_cooldown = 0
        end
    end

    -- 我方炮台AI（强化版：优先级选择、预测射击）
    for i, turret in ipairs(game.turrets) do
        -- 强化AI 1: 目标选择与锁定
        local target = nil
        -- turret.target_lock_timer = turret.target_lock_timer + dt -- 如果之前有这个字段

        -- 简化目标选择，直接找最好的
        target = game:findBestTargetForTurret(turret)

        -- 更新导弹炮台的独立冷却时间
        if turret.type == "导弹炮" then
            if turret.missile_cooldown > 0 then
                turret.missile_cooldown = turret.missile_cooldown - dt
            end
        end

        turret.last_shot = turret.last_shot + dt
        if turret.last_shot >= turret.fire_rate and target then
            -- 获取当前等级的伤害倍增
            local damage_mult = game.level_upgrades[game.current_level].damage_mult or 1
            -- 简化预测射击，直接用当前目标位置
            local predicted_target_x, predicted_target_y = target.x, target.y

            local barrel_x, barrel_y = game:getBarrelEnd(turret.x, turret.y, turret.angle, turret.barrel_length)

            -- 根据炮台类型执行不同攻击，并应用伤害倍增
            if turret.type == "标准炮" then
                game:fireBullet(barrel_x, barrel_y, turret.angle, predicted_target_x, predicted_target_y, false, damage_mult)
            elseif turret.type == "散弹炮" then
                if math.random(1, 2) == 1 then  -- 50%概率发射散弹
                    game:fireSpreadShot(barrel_x, barrel_y, turret.angle, damage_mult)
                else
                    game:fireBullet(barrel_x, barrel_y, turret.angle, predicted_target_x, predicted_target_y, false, damage_mult)
                end
            elseif turret.type == "激光炮" then
                -- 激光是即时的
                if math.random(1, 3) == 1 then  -- 33%概率发射激光
                    game:fireLaser(barrel_x, barrel_y, turret.angle, damage_mult)
                end
            elseif turret.type == "追踪炮" then
                game:fireBullet(barrel_x, barrel_y, turret.angle, predicted_target_x, predicted_target_y, false, damage_mult)
            elseif turret.type == "导弹炮" then
                -- 导弹炮逻辑：检查独立冷却
                if turret.missile_cooldown <= 0 then
                    game:fireMissile(barrel_x, barrel_y, predicted_target_x, predicted_target_y, false, damage_mult)
                    turret.missile_cooldown = game.missile_cooldown_time -- 重置冷却
                else
                     -- 冷却中，可以改为发射普通子弹作为后备
                     if math.random(1, 3) == 1 then -- 1/3概率尝试
                        game:fireBullet(barrel_x, barrel_y, turret.angle, predicted_target_x, predicted_target_y, false, damage_mult)
                     end
                end
            end
            turret.last_shot = 0
        end

        -- 更新炮管角度以瞄准目标
        if target then
            local dx = (predicted_target_x or target.x) - turret.x
            local dy = (predicted_target_y or target.y) - turret.y
            turret.angle = math.atan2(dy, dx)
        else
            -- 无目标时使用调试角度
            turret.angle = game.debug_turret_angle
        end
    end

    -- 生成极高密度敌人（丧尸海）
    game.last_enemy = game.last_enemy + dt
    if game.last_enemy >= game.enemy_rate then
        game:createEnemy()
        game.last_enemy = 0
    end
    -- 更新玩家子弹 (包括普通子弹和散弹)
    for i = #game.player_bullets, 1, -1 do
        local bullet = game.player_bullets[i]
        bullet.x = bullet.x + bullet.vx * dt
        bullet.y = bullet.y + bullet.vy * dt
        bullet.life = bullet.life - dt
        if bullet.life <= 0 or bullet.y < -20 or bullet.y > 620 or bullet.x < -20 or bullet.x > 820 then
            table.remove(game.player_bullets, i)
        end
    end
    -- 更新激光束
    for i = #game.laser_beams, 1, -1 do
        local laser = game.laser_beams[i]
        laser.duration = laser.duration - dt
        if laser.duration <= 0 then
            table.remove(game.laser_beams, i)
        end
    end
    -- 更新导弹
    for i = #game.missiles, 1, -1 do
        local missile = game.missiles[i]
        missile.x = missile.x + missile.vx * dt
        missile.y = missile.y + missile.vy * dt
        missile.life = missile.life - dt

        -- 检查导弹是否飞出屏幕或超时
        if missile.life <= 0 or missile.y < -20 or missile.y > 620 or missile.x < -20 or missile.x > 820 then
            table.remove(game.missiles, i)
        else
            -- 简单的接近目标点爆炸逻辑
            if missile.target_x and missile.target_y then
                local distance_to_target = math.sqrt((missile.x - missile.target_x)^2 + (missile.y - missile.target_y)^2)
                -- 如果距离目标点很近 (< 10) 或者距离开始增大 (可能已飞过)，则爆炸
                local prev_distance = math.sqrt((missile.x - missile.vx * dt - missile.target_x)^2 + (missile.y - missile.vy * dt - missile.target_y)^2)
                if distance_to_target < 10 or distance_to_target > prev_distance then
                     -- 触发爆炸
                    game:triggerMissileExplosion(missile)
                    table.remove(game.missiles, i)
                end
            end
        end
    end
    -- 更新爆炸效果
    for i = #game.explosions, 1, -1 do
        local explosion = game.explosions[i]
        explosion.duration = explosion.duration - dt

        -- 如果是核弹爆炸，让它逐渐扩大
        if explosion.is_nuke and explosion.radius < explosion.max_radius then
            -- 简单的线性增长
            explosion.radius = explosion.radius + (explosion.max_radius / explosion.duration) * dt
            if explosion.radius > explosion.max_radius then
                 explosion.radius = explosion.max_radius
            end
        end

        if explosion.duration <= 0 then
            -- 如果是核弹爆炸，在消失时清除范围内的敌人
            if explosion.is_nuke then
                local nuke_center_x, nuke_center_y = explosion.x, explosion.y
                local nuke_radius = explosion.max_radius
                local enemies_cleared = 0
                for j = #game.enemies, 1, -1 do
                    local enemy = game.enemies[j]
                    local distance = math.sqrt((enemy.x + enemy.width/2 - nuke_center_x)^2 + (enemy.y + enemy.height/2 - nuke_center_y)^2)
                    if distance <= nuke_radius then
                        table.remove(game.enemies, j)
                        game.score = game.score + 5 * (enemy.max_health or 1) -- 根据敌人血量加分
                        enemies_cleared = enemies_cleared + 1
                    end
                end
                print("核弹爆炸清理完成，清除了 " .. enemies_cleared .. " 个敌人")
            end
            table.remove(game.explosions, i)
        end
    end
    -- 更新敌人
    for i = #game.enemies, 1, -1 do
        local enemy = game.enemies[i]
        enemy.y = enemy.y + enemy.speed * dt
        if enemy.y > 620 then
            table.remove(game.enemies, i)
        end
    end

    -- --- 敌人之间以及与边界的碰撞检测 ---
    local screen_width, screen_height = 800, 600
    local push_force = 50 -- 分离时施加的力的大小（像素/秒）
    for i, enemy in ipairs(game.enemies) do
        local moved = true
        local attempts = 0
        local max_attempts = 5 -- 防止无限循环

        while moved and attempts < max_attempts do
            moved = false
            attempts = attempts + 1

            -- 1. 检查与屏幕边界的碰撞 (左右边界)
            if enemy.x < 0 then
                enemy.x = 0
                moved = true
            elseif enemy.x + enemy.width > screen_width then
                enemy.x = screen_width - enemy.width
                moved = true
            end

            -- 2. 检查与其他敌人的碰撞
            for j = i + 1, #game.enemies do -- 只检查列表中当前敌人之后的敌人，避免重复检查
                local other = game.enemies[j]
                -- 简单的AABB碰撞检测
                if not (enemy.x > other.x + other.width or
                        enemy.x + enemy.width < other.x or
                        enemy.y > other.y + other.height or
                        enemy.y + enemy.height < other.y) then

                    -- 发生碰撞，需要分离
                    -- 计算重叠深度
                    local overlap_x = math.min(enemy.x + enemy.width - other.x, other.x + other.width - enemy.x)
                    local overlap_y = math.min(enemy.y + enemy.height - other.y, other.y + other.height - enemy.y)

                    -- 沿重叠最小的方向分离
                    if overlap_x < overlap_y then
                        -- 水平方向分离
                        if enemy.x < other.x then
                            -- enemy 在 other 左边
                            local separation = overlap_x / 2
                            enemy.x = enemy.x - separation * dt * push_force
                            other.x = other.x + separation * dt * push_force
                        else
                            -- enemy 在 other 右边
                            local separation = overlap_x / 2
                            enemy.x = enemy.x + separation * dt * push_force
                            other.x = other.x - separation * dt * push_force
                        end
                    else
                        -- 垂直方向分离 (主要在Y轴移动，所以X轴分离可能更重要，但还是加上)
                         if enemy.y < other.y then
                            -- enemy 在 other 上面
                            local separation = overlap_y / 2
                            enemy.y = enemy.y - separation * dt * push_force
                            other.y = other.y + separation * dt * push_force
                        else
                            -- enemy 在 other 下面
                            local separation = overlap_y / 2
                            enemy.y = enemy.y + separation * dt * push_force
                            other.y = other.y - separation * dt * push_force
                        end
                    end
                    moved = true -- 标记为已移动，可能需要再次检查
                end
            end
        end
        -- 确保敌人被推离边界后不会超出屏幕 (作为最终检查)
        if enemy.x < 0 then enemy.x = 0 end
        if enemy.x > screen_width - enemy.width then enemy.x = screen_width - enemy.width end
        -- Y轴通常向下移动，碰撞检测主要在边界移除时进行，这里可以简化
        -- if enemy.y < 0 then enemy.y = 0 end -- 一般不需要
        -- if enemy.y > screen_height - enemy.height then enemy.y = screen_height - enemy.height end -- 会被移除
    end
    -- --- 敌人碰撞检测结束 ---

    -- 碰撞检测 - 子弹 vs 敌人 (player_bullets 包含普通子弹和散弹)
    for i = #game.player_bullets, 1, -1 do
        local bullet = game.player_bullets[i]
        for j = #game.enemies, 1, -1 do
            local enemy = game.enemies[j]
            if bullet.x < enemy.x + enemy.width and
               bullet.x + bullet.width > enemy.x and
               bullet.y < enemy.y + enemy.height and
               bullet.y + bullet.height > enemy.y then
                enemy.health = enemy.health - (bullet.damage or 1) -- 使用子弹的伤害值
                if enemy.health <= 0 then
                    table.remove(game.enemies, j)
                    game.score = game.score + 5 * (enemy.max_health or 1) -- 根据敌人血量加分
                end
                table.remove(game.player_bullets, i)
                break
            end
        end
    end
    -- 碰撞检测 - 激光 vs 敌人
    for i = #game.laser_beams, 1, -1 do
        local laser = game.laser_beams[i]
        for j = #game.enemies, 1, -1 do
            local enemy = game.enemies[j]
            -- 激光线段碰撞检测
            local laser_end_x = laser.x + laser.dx * laser.length
            local laser_end_y = laser.y + laser.dy * laser.length
            if (laser.x < enemy.x + enemy.width and laser_end_x > enemy.x and
                laser.y < enemy.y + enemy.height and laser_end_y > enemy.y) then
                enemy.health = enemy.health - laser.damage -- 使用激光的伤害值
                if enemy.health <= 0 then
                    table.remove(game.enemies, j)
                    game.score = game.score + 8 * (enemy.max_health or 1) -- 根据敌人血量加分
                end
            end
        end
    end
end
-- 渲染游戏画面
function love.draw()
    -- 绘制背景
    love.graphics.setColor(0, 0, 0.05)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    love.graphics.setColor(1, 1, 1)
    -- 绘制玩家
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", game.player_x - 12, game.player_y - 10, 24, 20)
    -- 绘制玩家炮管（长宽已对调）
    love.graphics.setColor(0.4, 0.4, 0.4) -- 深灰色
    love.graphics.push()
    love.graphics.translate(game.player_x, game.player_y)
    love.graphics.rotate(game.player_angle)
    -- 对调长宽: (-1.5, -3, 15, 3) 代替 (-1.5, -15, 3, 15)
    love.graphics.rectangle("fill", -1.5, -3, 15, 3)
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1) -- 重置颜色

    -- 绘制我方炮台和炮管
    for _, turret in ipairs(game.turrets) do
        -- 绘制炮台底座
        if turret.type == "标准炮" then
            love.graphics.setColor(0, 0.8, 1)  -- 蓝色
        elseif turret.type == "散弹炮" then
            love.graphics.setColor(1, 0.5, 0)  -- 橙色
        elseif turret.type == "激光炮" then
            love.graphics.setColor(1, 0, 1)    -- 紫色
        elseif turret.type == "追踪炮" then
            love.graphics.setColor(0, 1, 1)    -- 青色
        elseif turret.type == "导弹炮" then
            love.graphics.setColor(1, 0.8, 0)  -- 金色/黄色
        end
        love.graphics.rectangle("fill", turret.x - 10, turret.y - 7, 20, 14)

        -- 绘制炮管（长宽已对调）
        love.graphics.setColor(0.2, 0.2, 0.2)  -- 深灰色炮管
        love.graphics.push()
        love.graphics.translate(turret.x, turret.y)
        love.graphics.rotate(turret.angle)
        -- 对调长宽: (-1.5, -3, length, 3) 代替 (-1.5, -length, 3, length)
        love.graphics.rectangle("fill", -1.5, -3, turret.barrel_length, 3)
        love.graphics.pop()
        love.graphics.setColor(1, 1, 1) -- 重置颜色
    end

    -- 绘制玩家子弹 (包括普通子弹和散弹)
    love.graphics.setColor(1, 1, 0)
    for _, bullet in ipairs(game.player_bullets) do
        game:safePrint(bullet.char, bullet.x - 5, bullet.y - 5)
    end
    love.graphics.setColor(1, 1, 1)

    -- 绘制导弹
    love.graphics.setColor(1, 0.5, 0) -- 橙色
    for _, missile in ipairs(game.missiles) do
        love.graphics.rectangle("fill", missile.x - missile.width/2, missile.y - missile.height/2, missile.width, missile.height)
    end
    love.graphics.setColor(1, 1, 1)

    -- 绘制爆炸效果
    for _, explosion in ipairs(game.explosions) do
        local alpha = explosion.duration / (explosion.is_nuke and 1.0 or game.explosion_duration)
        if explosion.is_nuke then
            love.graphics.setColor(1, 1, 0, alpha * 0.8) -- 黄色
            love.graphics.circle("fill", explosion.x, explosion.y, explosion.radius)
            love.graphics.setColor(1, 0.5, 0, alpha * 0.9) -- 橙色
            love.graphics.circle("fill", explosion.x, explosion.y, explosion.radius * 0.7)
            love.graphics.setColor(1, 1, 1, alpha) -- 白色
            love.graphics.circle("fill", explosion.x, explosion.y, explosion.radius * 0.3)
        else
            love.graphics.setColor(1, 0.5, 0, alpha * 0.7) -- 橙红色
            love.graphics.circle("fill", explosion.x, explosion.y, explosion.radius)
            love.graphics.setColor(1, 1, 1, alpha * 0.9) -- 白色核心
            love.graphics.circle("fill", explosion.x, explosion.y, explosion.radius * 0.3)
        end
    end
    love.graphics.setColor(1, 1, 1) -- 重置颜色

    -- 绘制激光束
    love.graphics.setColor(1, 0, 0)
    love.graphics.setLineWidth(3)
    for _, laser in ipairs(game.laser_beams) do
        local end_x = laser.x + laser.dx * laser.length
        local end_y = laser.y + laser.dy * laser.length
        love.graphics.line(laser.x, laser.y, end_x, end_y)
    end
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
    -- 绘制敌人概念（不同类型，带血条）
    for _, enemy in ipairs(game.enemies) do
        -- 使用敌人自身的颜色
        love.graphics.setColor(enemy.color)
        love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)

        -- 绘制血条 (如果血量小于最大值)
        if enemy.health < enemy.max_health then
            local bar_width = enemy.width
            local bar_height = 3
            local bar_x = enemy.x
            local bar_y = enemy.y - bar_height - 1
            local health_ratio = enemy.health / enemy.max_health

            -- 血条背景
            love.graphics.setColor(0.5, 0.5, 0.5, 0.7) -- 灰色半透明背景
            love.graphics.rectangle("fill", bar_x, bar_y, bar_width, bar_height)
            -- 血条当前血量
            love.graphics.setColor(0, 1, 0, 0.8) -- 绿色半透明
            love.graphics.rectangle("fill", bar_x, bar_y, bar_width * health_ratio, bar_height)
        end

        -- 绘制概念文字
        love.graphics.setColor(0, 0, 0) -- 黑色文字
        game:safePrint(enemy.concept, enemy.x + (enemy.width / 2) - 5, enemy.y + (enemy.height / 2) - 5)
        -- 重置颜色
        love.graphics.setColor(1, 1, 1)
    end
    -- 显示游戏信息
    love.graphics.print("得分: " .. game.score, 10, 10)
    love.graphics.print("等级: " .. game.current_level, 10, 25)
    love.graphics.print("下一等级: " .. game.next_level_score, 10, 40)
    love.graphics.print("炮台: " .. #game.turrets, 10, 55)
    love.graphics.print("敌人: " .. #game.enemies, 10, 70)
    love.graphics.print("子弹: " .. math.max(0, #game.current_clip - game.clip_index + 1), 10, 85)
    if game.laser_cooldown > 0 then
        love.graphics.print("激光冷却: " .. string.format("%.1f", game.laser_cooldown) .. "s", 10, 100)
    else
        love.graphics.print("激光就绪", 10, 100)
    end
    if game.missile_cooldown > 0 then
        love.graphics.print("导弹冷却: " .. string.format("%.1f", game.missile_cooldown) .. "s", 10, 115)
    else
        love.graphics.print("导弹就绪", 10, 115)
    end
    if game.nuke_cooldown > 0 then
        love.graphics.print("核弹冷却: " .. string.format("%.1f", game.nuke_cooldown) .. "s", 10, 130)
    else
        love.graphics.print("核弹就绪", 10, 130)
    end
    -- 显示调试信息
    if game.show_debug_info then
        love.graphics.print("玩家角度: " .. string.format("%.2f", game.player_angle) .. " (" .. string.format("%.1f", math.deg(game.player_angle)) .. "度)", 10, 150)
        love.graphics.print("炮台角度: " .. string.format("%.2f", game.debug_turret_angle) .. " (" .. string.format("%.1f", math.deg(game.debug_turret_angle)) .. "度)", 10, 170)
        love.graphics.print("[Q/A] 调整玩家角度 [W/S] 调整炮台角度", 10, 190)
        love.graphics.print("[D] 切换调试显示", 10, 210)
    end
    -- 显示操作说明
    love.graphics.print("WASD: 移动 | 空格: 精准射击 | X: 散弹 | C: 激光 | Z: 导弹 | V: 核弹", 10, 550)
    love.graphics.print("炮管与子弹100%同步！可调试角度！", 10, 570)
    love.graphics.print("所有武器使用统一文本子弹！", 10, 590)
end
-- 处理按键事件
function love.keypressed(key)
    if key == "r" then
        print("重新加载当前文件...")
        game:loadClip()
    elseif key == "n" then
        print("切换到下一个文件...")
        game.file_index = game.file_index + 1
        game:loadClip()
    elseif key == "q" then
        game.debug_player_angle = game.debug_player_angle + 0.1
        print("玩家角度: " .. game.debug_player_angle)
    elseif key == "a" then
        game.debug_player_angle = game.debug_player_angle - 0.1
        print("玩家角度: " .. game.debug_player_angle)
    elseif key == "w" then
        game.debug_turret_angle = game.debug_turret_angle + 0.1
        print("炮台角度: " .. game.debug_turret_angle)
        for _, turret in ipairs(game.turrets) do
            turret.angle = game.debug_turret_angle
        end
    elseif key == "s" then
        game.debug_turret_angle = game.debug_turret_angle - 0.1
        print("炮台角度: " .. game.debug_turret_angle)
        for _, turret in ipairs(game.turrets) do
            turret.angle = game.debug_turret_angle
        end
    elseif key == "d" then
        game.show_debug_info = not game.show_debug_info
    end
end
