GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
PrefabFiles={
    "bm_hole_maker",
    "bm_wormhole",
}
Assets={

}
TUNING.BM_HOLE_LAN=GetModConfigData("language")

AddComponentPostInit("teleporter",function (self)
    local old=self.Activate
    self.Activate=function (self,doer,...)
        if not doer:HasTag("player") and self.migration_data ~= nil
            and self.inst:HasTag("bm_hole") and
            self.inst.target_world ~= TheShard:GetShardId() and
            Shard_IsWorldAvailable(self.inst.target_world) then
                if self.onActivate ~= nil then
                    self.onActivate(self.inst, doer, self.migration_data)
                end
                local message=doer:GetSaveRecord()
                doer:Remove()
                local data=json.encode(message)
                local x,y,z=self.inst.target_x,self.inst.target_y,self.inst.target_z
                SendModRPCToShard(SHARD_MOD_RPC["BM_RPC"]["TRANSFER"],self.inst.target_world,data,2,x,y,z)--给目标世界发送
                return true
        else
            return old(self,doer,...)
        end
    end
end)

local function transfer(now_world,data,message_type,x,y,z)
    if not data or not type then return end
    local message=json.decode(data)
    if message then
        if message_type==1 then
            local ents = TheSim:FindEntities(x, y, z, 2,{"bm_hole"}) or {}
            if ents[1] then
                ents[1].target_x=message.x
                ents[1].target_y=message.y
                ents[1].target_z=message.z
                ents[1].target_world=message.inst_world
                ents[1].components.teleporter:MigrationTarget(ents[1].target_world,message.x,message.y,message.z)
            end
        elseif message_type==2 then
            local ents = TheSim:FindEntities(x, y, z, 2,{"bm_hole"}) or {}
            if ents[1] then
                local item = SpawnSaveRecord(message)
                ents[1].components.teleporter:ReceiveItem(item)
            end
        end
    end
end
AddShardModRPCHandler("BM_RPC", "TRANSFER", transfer)

AddRecipe("hole_maker",{Ingredient("lureplantbulb", 2), Ingredient("nightmarefuel",5), Ingredient("reviver", 1)},
RECIPETABS.MAGIC,TECH.MAGIC_TWO,nil,nil,nil,nil,nil,"images/bm_wormhole.xml","bm_wormhole.tex")
STRINGS.NAMES[string.upper("hole_maker")]="Wacky wormhole"
STRINGS.NAMES[string.upper("bm_wormhole")]="Wacky wormhole"
STRINGS.RECIPE_DESC[string.upper("hole_maker")]="Connecting a tunnel with a Wacky wormhole."


STRINGS.CHARACTERS.GENERIC.DESCRIBE[string.upper("hole_maker")]=STRINGS.CHARACTERS.GENERIC.DESCRIBE[string.upper("wormhole")]
STRINGS.CHARACTERS.GENERIC.DESCRIBE[string.upper("bm_wormhole")]=STRINGS.CHARACTERS.GENERIC.DESCRIBE[string.upper("wormhole")]