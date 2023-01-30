Store = {
  store = system.getInfo("platform") == "android" and require("plugin.google.iap.billing.v2") or require("store"),
  isInit = false,
  cb = nil,
  products = {}
}

function Store:new()

  local this = self

  local function onEvent(e)
    if self.cb  ~= nil then
      self.cb(e.transaction.state)
      self.cb = nil
    end
  end

  if self.isInit == false then
    self.store.init(onEvent)
  end

  self.isInit = true
  return self
end

function Store:purchase(id, cb)
  if self.cb == nil and self.store.isActive == true then
    self.cb = cb
    self.store.purchase(id)
    return true
  end
  return false
end

function Store:load(length, cb)
  local arr = {}

  for i = 1, length do
    arr[i] = tostring(i)
  end
  self.store.loadProducts(arr, function(event)
    for i = 1, #event.products do
      self.products[tonumber(event.products[i].productIdentifier)] = event.products[i]
    end
  end)
end

function Store:consume(id)
  self.store.consumePurchase(id)
end

function Store:destroy()
  self.next = nil
  self.isInit = false
end

return Store
