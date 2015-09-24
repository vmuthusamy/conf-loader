require 'bundler'
require 'pp'
require 'csv'
require_relative 'conf_loader/override_reconciliation.rb'
require_relative 'conf_loader/group_hash.rb'

class ConfLoader
  attr_reader :overrides, :file_path

  $overrides_count = Hash.new
  $group_name = nil

  GROUP_PATTERN = /^\[[^\]\r\n]+\](?:\r?\n(?:[^\[\r\n].*)?)*/
  ENABLED_VALUES = ['1', 'yes', 'true']
  DISABLED_VALUES = ['0', 'no', 'false']


  def initialize(file_path, overrides=[])
    @file_path = file_path
    @overrides = overrides
  end

  def process
    rank_overrides(overrides)
    # Initially i thought about loading the file into memory
    # After i read the requirements few times I decided it might not be a good idea
    # Decided to use this route after reading http://stackoverflow.com/a/5546681/396850
    File.foreach(file_path) do |line|
      unless line
        next
      end
      parse(line)
    end
    load_from_config_store(config_store)
  end

  # if overrides are passed in, creates a hash of overrides to its index
  # in the array, this is to ensure that override with maximum index
  # value is prioritized in reconciliation
  def rank_overrides(overrides)
    $overrides_count= Hash[overrides.each_with_index.map {|x,i| [x.to_s, i+1]}]
  end

  # core business logic resides in this method.
  # The idea is to parse each line, figure if it has a [config] associated
  # if so parse its properties and finally based on the overrides passed in
  # reconcile the correct value to those properties if any of them has multiple
  # configurations.
  # Modularized and delegated this to additional helper methods for readability.
  def parse(line)
    line.strip!
    line = remove_comments_from_line(line)

    if line.empty?
      return
    end
    if (parsedGroupName = parse_group_name(line))
      $group_name = parsedGroupName
    elsif (kv_pair_obj = parse_key_value(line))
      k,v=kv_pair_obj
      parse_and_reconcile_overridden_values(k,v,$group_name)
    else
      raise 'unrecognized format' << line
    end
  end

  # replace anything starting with ; with white space
  def remove_comments_from_line(line)
    line.gsub(/;.*$/, '')
  end

  # pattern match a line to see if it has the GROUP_PATTERN
  # e.g [FTP]
  def parse_group_name(line)
    groupPattern = line.match(GROUP_PATTERN)
    unless groupPattern
      return nil
    end

    group = groupPattern[0]

    group = group[1..group.length - 2]

    if group =~ /\s/
      raise 'Illegal Character: Group name contains whitespace ' << group
    end

    group
  end

  # this does a simple split based on '='
  # once key and values are split it trims the quotes around them
  # if they are strings.
  def parse_key_value(line)
    parts = line.split('=')
    return nil if parts.length != 2

    k, v = parts.map(&:strip)
    v = CSV.parse_line(v).map{|s| removeQuotes(s) }
    v = v.first if v.length == 1
    [k, v]
  end

  # used by parse_key_value() method to trim the quotes
  def removeQuotes(str)
    str.gsub(/^[\'\"]/, '').gsub(/[\'\"]$/, '')
  end



  # If not for overrides the logic is relatively small.
  # This method checks for existence for Config<Overridden>
  # if there is no override value is simply stored into the
  # OverrideReconciliation object's value field into the bucket of groupName.
  # if there is an override present the reconciliation is done
  # by using the overrides_count hash which was preprocessed earlier
  # and the OverrideReconciliation
  # object's override and overridden_value are updated accordingly
  # and it's stored of the form below
  # [:group]=>[:propertyKey]=>[OverrideReconciliationObject] is stored in memory

  def parse_and_reconcile_overridden_values(key,value,group)
    key, override = parse_key_with_override(key)
    extractedValue = extract_value(value)

    override_reconciliation = get_value(key,group)
    if override_reconciliation
      if override
        if override_reconciliation.has_new_override_more_priority(override, $overrides_count)
          override_reconciliation.override         = override
          override_reconciliation.overridden_value = extractedValue
        end
      else
        override_reconciliation.value = extractedValue
      end
    else
      set_value(key, OverrideReconciliation.new(extractedValue, override, extractedValue),group)
    end
  end

  # Looks for PropertyKey<Override> to extract key
  # and the override individually
  def parse_key_with_override(str)
    pattern = /(?<name>\w+)(\<(?<override>\w+)\>)?/
    matcher   = pattern.match(str)
    raise "unrecognized key format: #{str.inspect}" unless matcher

    [matcher[:name], matcher[:override]].compact
  end

  def extract_value(val)
    if val.is_a?(Array)
      return val
    end
    if ENABLED_VALUES.include?(val)
      return true
    end
    if DISABLED_VALUES.include?(val)
      return false
    end

    int = val.to_i
    if int.to_s == val
      return int
    end

    val
  end

  # Recursive helper to extract the
  # [:group]=>[:propertyKey]=>[OverrideReconciliationObject]
  # into a config object which can be queried.
  # The logic ascertains if its a Hash or an Object if it's an hash
  # its value is passed recursively or if its an OverrideReconciliation
  # object its overridden value is extracted.
  def load_from_config_store(hash)
    hash.each_with_object(GroupHash.new) do |(key, value), memo|
      memo[key.to_sym] = case value
                           when Hash
                             load_from_config_store(value)
                           when OverrideReconciliation
                             value.overridden_value
                           else
                             raise "unexpected value when converting: #{value}"
                         end
    end
  end


  def config_store
    @memory ||= Hash.new { |hash, key| hash[key] = {} }
  end

  def get_value(key,group)
    config_store[group][key]
  end

  def set_value(key, value,group)
    config_store[group][key] = value
  end

end

