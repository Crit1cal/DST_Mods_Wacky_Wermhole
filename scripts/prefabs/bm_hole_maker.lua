require "prefabutil"
local assets =
{
    Asset("ANIM", "anim/hole_maker.zip"),
    Asset("ATLAS", "images/bm_wormhole.xml"),
    Asset("IMAGE", "images/bm_wormhole.tex"),
}
local function item_ondeploy(inst, pt, deployer)
    local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(pt:Get())

    local obj = SpawnPrefab("bm_wormhole")
	obj.Transform:SetPosition(cx, cy, cz)
    if inst.one_worldid and inst.one_hole.x then
        obj:OnDespawn_bm(inst.one_worldid,inst.one_hole.x,inst.one_hole.y,inst.one_hole.z)--执行连接函数
    end

    if not inst.one_worldid then
        inst.one_worldid=TheShard:GetShardId()
        inst.one_hole={}
        inst.one_hole.x=cx
        inst.one_hole.y=cy
        inst.one_hole.z=cz
    end
    inst.components.finiteuses:Use(1)
    if inst:IsValid() then
        -- inst.components.inventoryitem:RemoveFromOwner(true)
        deployer.components.inventory:GiveItem(inst,nil ,deployer:GetPosition() or nil)
	end
end
--Map:IsAboveGroundAtPoint

local function can_plow_tile(inst, pt, mouseover, deployer)
	local x, z = pt.x, pt.z
	if not TheWorld.Map:IsAboveGroundAtPoint(x, 0, z) then
		return false
	end
	local ents = TheWorld.Map:GetEntitiesOnTileAtPoint(x, 0, z)
	for _, ent in ipairs(ents) do
		if ent ~= inst and ent ~= deployer and not (ent:HasTag("NOBLOCK") or ent:HasTag("locomotor") or ent:HasTag("NOCLICK") or ent:HasTag("FX") or ent:HasTag("DECOR")) then
			return false
		end
	end

	return true
end

local function onsave(inst,data)
    data.one_worldid=inst.one_worldid
    data.one_hole={}
    if next(inst.one_hole) then
        data.one_hole.x=inst.one_hole.x
        data.one_hole.y=inst.one_hole.y
        data.one_hole.z=inst.one_hole.z
    end
end

local function onload(inst,data,newents)
    inst.one_worldid=data.one_worldid
    if next(data.one_hole) then
        inst.one_hole.x=data.one_hole.x
        inst.one_hole.y=data.one_hole.y
        inst.one_hole.z=data.one_hole.z
    end
end

local function item_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("hole_maker")
    inst.AnimState:SetBuild("hole_maker")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("usedeploystring")

	MakeInventoryFloatable(inst, "small", 0.1, 0.8)

	inst._custom_candeploy_fn = can_plow_tile

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    inst.one_hole={}

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/bm_wormhole.xml"
    inst.components.inventoryitem.imagename = "bm_wormhole"

    inst:AddComponent("deployable")
	inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
    inst.components.deployable.ondeploy = item_ondeploy

	inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetMaxUses(2)
    inst.components.finiteuses:SetUses(2)

    inst.OnSave=onsave
    inst.OnLoad=onload

    MakeHauntableLaunch(inst)

    return inst
end


local function placer_fn()
    local inst = CreateEntity()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("teleporter_worm")
    inst.AnimState:SetBuild("teleporter_worm_build")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetLightOverride(1)

    inst:AddComponent("placer")
    inst.components.placer.snap_to_tile = true

	inst.outline = SpawnPrefab("tile_outline")
	inst.outline.entity:SetParent(inst.entity)
	inst.components.placer:LinkEntity(inst.outline)
    return inst
end

return  Prefab("hole_maker", item_fn, assets),
		Prefab("hole_maker_placer", placer_fn)

