require 'json'

class Flash
  def initialize(req)
    if req.cookies["_rails_lite_app_flash"]
      @last_flash = JSON.parse(req.cookies["_rails_lite_app_flash"])
    else
      @last_flash = {}
    end
    @flash = {}
  end

  def [](key)
    @last_flash[key]
  end

  def []=(key, val)
    @flash[key] = val
    @last_flash[key] = val
  end

  def now
    @last_flash
  end

  def store_flash(res)
    value = @flash.to_json
    res.set_cookie("_rails_lite_app_flash", { path: "/", value: value })
  end
end
