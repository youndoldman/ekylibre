# require 'procedo/engine/intervention/product_parameter'

module Procedo
  module Engine
    class Intervention
      class Target < Procedo::Engine::Intervention::ProductParameter
        attr_reader :new_group, :new_container
        attr_accessor :new_variant

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          attributes = Maybe(attributes)
          @new_group = Product.find_by(id: attributes[:new_group_id].to_i.or_else(0))
          @new_variant = ProductNatureVariant.find_by(id: attributes[:new_variant_id].to_i.or_else(0))
        end

        def new_group_id
          @new_group ? @new_group.id : nil
        end

        def new_group=(record)
          self.new_group_id = record.id
        end

        def new_group_id=(id)
          @new_group = Product.find_by(id: id)
          impact_dependencies!(:new_group)
        end

        def new_variant_id
          new_variant ? new_variant.id : nil
        end

        def new_variant_id=(id)
          self.new_variant = ProductNatureVariant.find_by(id: id)
        end

        def mergeable_with
          @product.present? && !@product.population_counting_unitary? && @product.matching_product(at: time_of_creation, container: @new_container_id)
        end

        def to_hash
          hash = super
          hash[:new_group_id] = new_group_id if @new_group
          hash[:attributes] ||= {}
          hash[:attributes][:new_container_id] ||= {}
          hash[:attributes][:new_container_id][:dynascope] ||= {}
          hash[:attributes][:new_container_id][:dynascope][:of_expression] ||= 'is building_division'
          hash[:attributes][:new_container_id][:dynascope][:of_expression] << " or can store(#{@product.variety})" if @product
          hash[:attributes][:merge_stocks] ||= {}
          hash[:attributes][:merge_stocks][:with] = mergeable_with
          hash[:new_variant_id] = new_variant_id unless new_variant_id.nil?
          hash
        end

        def env
          super.merge(new_group: new_group)
        end
      end
    end
  end
end
