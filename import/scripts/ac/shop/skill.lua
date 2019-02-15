local mt = ac.skill['@商店物品']

function mt:onAdd()
    self.timer = ac.loop(1, function ()
        self:update()
    end)
end

function mt:onRemove()
    if self.timer then
        self.timer:remove()
    end
end

function mt:onCastShot()
    local item, err = self.shop:buyItem(self.itemName)
    if not item then
        self:getOwner():getOwner():message {
            text = '{err}',
            data = {
                err = err,
            },
            color = {
                err = 'ffff11',
            }
        }
    end
end

function mt:update()
    local item = self.item
    self:setOption('title', item.title)
    self:setOption('icon', item.icon)

    local player = ac.localPlayer()
    local priceDescription = {}
    if type(item.price) == 'table' then
        for _, data in ipairs(item.price) do
            local left = player:get(data.type) - data.value
            if left >= 0 then
                priceDescription[#priceDescription+1] = ('%s： |cff11ff11%.f|r'):format(data.type, data.value)
            else
                priceDescription[#priceDescription+1] = ('%s： |cffff8811%.f(%.f)|r'):format(data.type, data.value, left)
            end
        end
    end
    if #priceDescription > 0 then
        self:setOption('description', ([[
%s

%s
]]):format(item.description, table.concat(priceDescription, '\r\n')))
    else
        self:setOption('description', item.description)
    end
end
