class StimulusReflex::PermissiveOpenStruct < OpenStruct
  delegate :dig, to: :@table
end
