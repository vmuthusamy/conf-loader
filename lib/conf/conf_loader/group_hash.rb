class ConfLoader
  class GroupHash < Hash
    def method_missing(meth, *args, &block)
      if has_key?(meth)
        self[meth]
      else
        nil
      end
    end
  end
end