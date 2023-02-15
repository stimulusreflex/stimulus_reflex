# frozen_string_literal: true

#
# Temporary fix until this PR gets merged:
# https://github.com/ruby/ostruct/pull/37
# Thanks to @Laykou
#
# Calling this in OpenStruct 0.5.2 fails:
# os = OpenStruct.new(class: "my-class", method: "post")

if defined?(OpenStruct::VERSION) && OpenStruct::VERSION == "0.5.2"
  class OpenStruct
    private def is_method_protected!(name)
      if !respond_to?(name, true)
        false
      elsif name.match?(/!$/)
        true
      else
        owner = method!(name).owner
        if owner.instance_of?(::Class)
          owner < ::OpenStruct
        else
          class!.ancestors.any? do |mod|
            return false if mod == ::OpenStruct
            mod == owner
          end
        end
      end
    end
  end
end
