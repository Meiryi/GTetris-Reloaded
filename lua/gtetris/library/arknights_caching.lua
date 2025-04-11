GTetris.CachedMaterial = GTetris.CachedMaterial || {}
GTetris.CachedSpineAnimation = GTetris.CachedSpineAnimation || {}

function GTetris.ClearCaches()
	GTetris.CachedMaterial = {}
	GTetris.CachedSpineAnimation = {}
	GTetris.Portraits = {}
end

function GTetris.CacheSpineAnimations(basefolder, entityid)
	if(GTetris.CachedSpineAnimation[entityid]) then
		return GTetris.CachedSpineAnimation[entityid]
	end
	local animations = {}
	local _, sides = file.Find("materials/arknights/assets/"..basefolder.."/"..entityid.."/*", "GAME")
	if(#sides <= 0) then -- Invalid path or entity id
		return nil
	end
	for _, side in pairs(sides) do
		animations[side] = {}
		local _, anims = file.Find("materials/arknights/assets/"..basefolder.."/"..entityid.."/"..side.."/*", "GAME")
		for _, anim in pairs(anims) do
			animations[side][anim] = {}
			local animation_frames = file.Find("materials/arknights/assets/"..basefolder.."/"..entityid.."/"..side.."/"..anim.."/*.png", "GAME")
			for _, frame in pairs(animation_frames) do
				local material = Material("arknights/assets/"..basefolder.."/"..entityid.."/"..side.."/"..anim.."/"..frame, "smooth")
				table.insert(animations[side][anim], material)
			end
		end
	end
	GTetris.CachedSpineAnimation[entityid] = animations
end

function GTetris.RefreshMaterialCaches()
	for k,v in pairs(GTetris.CachedMaterial) do
		GTetris.CachedMaterial[k] = Material(k, "smooth")
	end
end

GTetris.MaterialIndex = GTetris.MaterialIndex || 0
function GTetris.GetCachedVMaterial(material)
	if(!GTetris.CachedMaterial[material]) then
		GTetris.CachedMaterial[material] = CreateMaterial("arknights_material"..GTetris.MaterialIndex, "VertexLitGeneric", {
			["$basetexture"] = material,
			["$translucent"] = 1,
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1,
			["$noclull"] = 0,
		})
		GTetris.MaterialIndex = GTetris.MaterialIndex + 1
	end
	return GTetris.CachedMaterial[material]
end

function GTetris.GetCachedMaterial(material)
	if(!GTetris.CachedMaterial[material]) then
		GTetris.CachedMaterial[material] = Material(material, "smooth")
	end
	return GTetris.CachedMaterial[material]
end

function GTetris.CachePortraits()
	local f = file.Find("materials/arknights/operators/portraits/*.png", "GAME")
	for k,v in ipairs(f) do
		local n = string.Replace(v, ".png", "")
		GTetris.Portraits[n] = Material("materials/arknights/operators/portraits/"..v, "smooth")
	end
end