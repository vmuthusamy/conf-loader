class ConfLoader
  class OverrideReconciliation < Struct.new(:value, :override, :overridden_value)
    def has_new_override_more_priority(new_override, overrides_to_index_map)
      if !overrides_to_index_map[new_override]
        return false
      end
      if !override
        return true
      end


      overrides_to_index_map[new_override].to_i > overrides_to_index_map[override].to_i
    end
  end
end