require 'active_record_lite'

class MyMassObject < MassObject
  set_attrs(:x, :y)
end

obj = MyMassObject.new(:x => :x_val, :y => :y_val)
p obj

# class MyClass < MassObject
#   set_attrs :x, :y
# end
#
# my_obj = MyClass.new
# my_obj.x = :x_val
# my_obj.y = :y_val
# p my_obj
