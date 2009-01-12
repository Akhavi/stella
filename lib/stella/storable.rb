
# TODO: Handle nested hashes and arrays. 

require 'yaml'
require 'utils/fileutil'

module Stella
  class Storable
    NICE_TIME_FORMAT = "%Y-%m-%d@%H:%M:%S".freeze unless defined? NICE_TIME_FORMAT
      
    SupportedFormats = %w{tsv csv yaml json}.freeze unless defined? SupportedFormats
    
    attr_accessor :format
    
    def format=(v)
      raise "Unsupported format: #{v}" unless SupportedFormats.member?(v)
      @format = v
    end
    
    def field_names
      raise "You need to override field_names (#{self.class})"
    end
    
    def dump(format=nil, with_titles=true)
      format ||= @format
      raise "Format not defined (#{format})" unless SupportedFormats.member?(format)
      send("to_#{format}", with_titles) 
    end
    
    def self.from_file(file_path=nil, format=nil)
      raise "Cannot read file (#{file_path})" unless File.exists?(file_path)
      format = format || File.extname(file_path).tr('.', '')
      me = self.send("from_#{format}", FileUtil.read_file_to_array(file_path))
      me.format = format
      me
    end
    def to_file(file_path=nil, with_titles=true)
      raise "Cannot store to nil path" if file_path.nil?
      format = File.extname(file_path).tr('.', '')
      format ||= @format
      FileUtil.write_file(file_path, dump(format, with_titles))
    end
  

    def self.from_hash(from={})
      return if !from || from.empty?
      me = self.new
      fnames = me.to_hash.keys
      fnames.each do |key|
        # NOTE: this will skip generated values b/c they don't have a setter method
        me.send("#{key}=", from[key]) if self.method_defined?("#{key}=")  
      end
      me
    end
    def to_hash(with_titles=true)
      tmp = {}
      field_names.each do |fname|
        tmp[fname] = self.send(fname.to_s)
      end
      tmp
    end
    

    def self.from_yaml(from=[])
      # from is an array of strings
      from_str = from.join('')
      hash = YAML::load(from_str)
      hash = from_hash(hash) if hash.is_a? Hash 
      hash
    end
    def to_yaml(with_titles=true)
      to_hash.to_yaml
    end
    

    def self.from_json(from=[])
      require 'json'
      # from is an array of strings
      from_str = from.join('')
      tmp = JSON::load(from_str)
      hash_sym = tmp.keys.inject({}) do |hash, key|
         hash[key.to_sym] = tmp[key]
         hash
      end
      hash_sym = from_hash(hash_sym) if hash_sym.is_a? Hash  
      hash_sym
    end
    def to_json(with_titles=true)
      require 'json'
      to_hash.to_json
    end
    
    def to_delimited(with_titles=false, delim=',')
      values = []
      field_names.each do |fname|
        values << self.send(fname.to_s)   # TODO: escape values
      end
      output = values.join(delim)
      output = field_names.join(delim) << $/ << output if with_titles
      output
    end
    def to_tsv(with_titles=false)
      to_delimited(with_titles, "\t")
    end
    def to_csv(with_titles=false)
      to_delimited(with_titles, ',')
    end
    def self.from_tsv(from=[])
      self.from_delimited(from, "\t")
    end
    def self.from_csv(from=[])
      self.from_delimited(from, ',')
    end
    
    def self.from_delimited(from=[],delim=',')
      return if from.empty?
      # We grab an instance of the class so we can 
      hash = {}
      
      fnames = values = []
      if (from.size > 1 && !from[1].empty?)
        fnames = from[0].chomp.split(delim)
        values = from[1].chomp.split(delim)
      else
        fnames = self.new.field_names
        values = from[0].chomp.split(delim)
      end
      
      fnames.each_with_index do |key,index|
        next unless values[index]
        number_or_string = (values[index].match(/[\d\.]+/)) ? values[index].to_f : values[index]
        hash[key.to_sym] = number_or_string
      end
      hash = from_hash(hash) if hash.is_a? Hash 
      hash
    end

  
  end
end