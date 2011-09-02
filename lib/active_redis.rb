require 'redis/connection/hiredis'
require 'redis'

module ActiveRedis
  include ActiveModel::Conversion

  def self.included(base)
    base.extend(ClassMethods)
    base.extend(ActiveModel::Naming)
  end

  def redis_fields
    self.class.redis_fields
  end

  def redis_belongs
    self.class.redis_belongs
  end

  module ClassMethods

    def define_fields *args
      @redis_fields = args
      args.each do |field|
        attr_writer field
      end
    end

    def redis_fields
      @redis_fields
    end

    def belongs_to *args
      @redis_belongs = args
      args.each do |field|
        attr_writer field
      end
    end

    def redis_belongs
      @redis_belongs
    end

  end

end