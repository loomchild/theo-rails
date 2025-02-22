module Theo
  module Rails
    ATTRIBUTE_NAME = /(?<name>[\w:@_][-\w:@_]*)/
    ATTRIBUTE_VALUE = /(?:(?:"(?<value>[^"]*)")|(?:'(?<value>[^']*)'))/
    ATTRIBUTE = /(?:(?:#{ATTRIBUTE_NAME.source}\s*=\s*#{ATTRIBUTE_VALUE.source})|#{ATTRIBUTE_NAME.source})/
    DYNAMIC_ATTRIBUTE = /(?:(?:#{ATTRIBUTE_NAME.source}\s*%=\s*#{ATTRIBUTE_VALUE.source})|(?:#{ATTRIBUTE_NAME.source}%))/
    RESERVED_ATTRIBUTE_NAME = %w[alias and begin break case class def do else elsif end ensure false for if in module next nil not or redo rescue retry return self super then true undef unless until when while yield].to_set
    ATTRIBUTES = /(?<attrs>(?:\s+#{ATTRIBUTE.source})*)/
    LITERAL_ATTRIBUTES = %i[path as yields collection].freeze
    PARTIAL_TAG = /(?:(?<partial>[A-Z]\w+)|(?<partial>_[\w-]+))/
    PARTIAL = /(?:<#{PARTIAL_TAG.source}#{ATTRIBUTES.source}\s*>(?<content>.*?)<\/\k<partial>>)|(?:<#{PARTIAL_TAG.source}#{ATTRIBUTES.source}\s*\/>)/m
    DYNAMIC_EXPRESSION = /^<%=([^%]*)%>$/

    class Theo
      def process(source)
        # Attributes
        source = source.gsub(DYNAMIC_ATTRIBUTE) do |_|
          match = Regexp.last_match

          name = match[:name]

          # See https://island94.org/2024/06/rails-strict-locals-local_assigns-and-reserved-keywords for more info
          value = match[:value] || (RESERVED_ATTRIBUTE_NAME.include?(name) ? "binding.local_variable_get('#{name}')" : name)

          "#{name}=\"<%= #{value} %>\""
        end

        # Partials
        source.gsub(PARTIAL) do |_|
          match = Regexp.last_match

          partial = match[:partial]

          attributes = match[:attrs] || ''
          content = match[:content]

          attributes = process_attributes(attributes)

          path = attributes.delete(:path)

          collection = attributes.delete(:collection)
          as = attributes.delete(:as)

          yields = attributes.delete(:yields)
          yields = " |#{yields}|" if yields

          locals = attributes.empty? ? '' : attributes.map { |k, v| "'#{k}': #{v}" }.join(', ')

          component = resolve_view_component(partial)
          is_partial = component.nil?

          if is_partial
            partial = partial.delete_prefix('_').underscore

            partial = "#{path}/#{partial}" if path

            as = as ? ", as: '#{as}'" : ''
            collection = ", collection: #{collection}#{as}" if collection

            if content
              locals = ", {#{locals}}" unless locals.empty?
              output = "<%= render '#{partial}'#{locals} do#{yields} %>#{process(content)}<% end %>"
            else
              locals = ", locals: {#{locals}}" unless locals.empty?
              output = "<%= render partial: '#{partial}'#{collection}#{locals} %>"
            end
          else
            if content
              output = "<%= render #{component}.new(#{locals}) do#{yields} %>#{process(content)}<% end %>"
            elsif collection
              locals = ", #{locals}" unless locals.empty?
              output = "<%= render #{component}.with_collection(#{collection}#{locals}) %>"
            else
              output = "<%= render #{component}.new(#{locals}) %>"
            end
          end

          output
        end
      end

      def process_attributes(attributes)
        attributes
          .gsub(ATTRIBUTE)
          .map { Regexp.last_match }
          .map do |attr|
            name = attr[:name].to_sym
            value = attr[:value]
            value = attribute(value) unless LITERAL_ATTRIBUTES.include?(name)
            [name, value]
          end
          .to_h
      end

      def attribute(source)
        # TODO: support attributes like "a<%= b %>c

        match = DYNAMIC_EXPRESSION.match(source)
        return match[1].strip if match

        "'#{source}'"
      end

      def view_component_loaded?
        @view_component_loaded ||= Object.const_defined?('ViewComponent')
      end

      def resolve_view_component(component)
        return unless view_component_loaded?

        # safe_constantize ensures PascalCase
        klass = component.safe_constantize || "#{component}Component".safe_constantize
        klass.name if klass && klass < ViewComponent::Base
      end

      def translate_location(spot, backtrace_location, source)
        result = ActionView::Template::Handlers::ERB.new.translate_location(spot, backtrace_location, source)

        return unless result.nil?

        # TODO: More precise location handling, see ERB::Util for inspiration
        lineno_delta = ActionView::Base.annotate_rendered_view_with_filenames ? 1 : 0
        spot[:first_lineno] -= lineno_delta
        spot[:last_lineno] -= lineno_delta
        spot[:first_column] = 0
        spot[:last_column] = 0
        spot[:script_lines] = source.lines
        spot
      end

      def call(template, source = nil)
        theo = process(source)

        ::Rails.logger.info "Theo is generating ERB: \n#{theo}"

        ActionView::Template::Handlers::ERB.call(template, theo)
      end
    end
  end
end
