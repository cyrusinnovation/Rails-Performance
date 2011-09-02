require 'redis/connection/hiredis'
require 'redis'

module ActiveRedis
  include ActiveModel::Conversion

  attr_reader :id

  def self.included(base)
    base.extend(ClassMethods)
    base.extend(ActiveModel::Naming)
  end

  #over write properties?
  #passing in an id can break things
  #requires initialize to be unused
  def initialize params={}
    params.each do |key, value|
      self.instance_variable_set to_instance_variable_symbol(key), value
    end
  end

  def redis_db
    self.class.redis_db
  end

  def redis_fields
    self.class.redis_fields
  end

  def redis_belongs
    self.class.redis_belongs
  end

  def table_name
    self.class.table_name
  end

  def to_instance_variable_symbol symbol
    ("@" + symbol.to_s).to_sym
  end

  #0 can be an id if somebody calls all and saves the tweet that shouldn't have been returned
  #first tweet will have id 1 otherwise
  def save!

    @id ||= redis_db.incr("#{table_name}:counter")

    redis_fields.each do |field|
      redis_db.set "#{table_name}:#{id}:#{field}", self.send(field)
    end

    redis_belongs.each do |parent_name|
      parent = self.send(parent_name)
      if parent
        redis_db.set "#{table_name}:#{id}:#{parent_name}_id", parent.id
        association_collection = parent.send(self.class.name.pluralize.downcase)
        association_collection << self
        parent.save!
      end
    end
  end

  #Not fully implemented - need to delete e.g., tweet off user. and reverse associations (see User)
#  def delete
#    redis_db.keys("#{table_name}:#{id}:*").each do |key|
#      redis_db.del key
#    end
#  end

  module ClassMethods

    #always reverse sorts
    #Always returns tweet(s), even if they don't exist
    #always returns tweet with id 0
    def all params={}
      redis_db.setnx "#{table_name}:counter", 0
      count = redis_db.get("#{table_name}:counter").to_i
      limit = params[:limit] ? count - params[:limit] + 1 : 0
      count.downto(limit).map do |id|
        find id
      end
    end

    def count
      (redis_db.get "#{table_name}:counter").to_i
    end

    def find id
      raise ActiveRecord::RecordNotFound if redis_db.keys("#{table_name}:#{id}*").blank?
      new({id: id.to_i})
    end


    def delete_all
      redis_db.keys("#{table_name}:*").each do |key|
        redis_db.del key
      end

      redis_belongs.each do |belong|
        Object::const_get(belong.to_s.capitalize).all.each do |instance|
          instance.send "delete_#{self.name.pluralize.downcase}".to_sym
        end
      end

      redis_db.set "#{table_name}:counter", 0
    end

    def table_name
      @table_name ||= self.name.pluralize.downcase

    end

    def redis_db
      @redis_db ||= Redis.new
    end

    def redis_fields
      @redis_fields
    end

    def field *args
      @redis_fields = args
      args.each do |field|
        define_method field do
          var = instance_variable_get(to_instance_variable_symbol(field))
          var ||= redis_db.get("#{table_name}:#{@id}:#{field}")
        end
        attr_writer field
      end
    end

    def belongs_to *args
      @redis_belongs = args
      args.each do |field|
        define_method field do
          var = instance_variable_get(to_instance_variable_symbol(field))
          var ||= Object::const_get(field.to_s.capitalize).find(redis_db.get("#{table_name}:#{@id}:#{field}_id"))
        end
        attr_writer field
      end
    end

    def redis_belongs
      @redis_belongs
    end

  end

end