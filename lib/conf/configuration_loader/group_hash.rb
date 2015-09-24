class ConfLoader
  class GroupHash < Hash
    def method_missing(name)
      self[name]
    end
  end
end