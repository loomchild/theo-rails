module Theo
  module Rails
    ATTRIBUTE_NAME = /[\w\-:@]+/
    ATTRIBUTE_VALUE = /(?:(?:"(?<value>[^"]*)")|(?:'(?<value>[^']*)'))/
    ATTRIBUTE = /(?:(?:(?<name>#{ATTRIBUTE_NAME.source})\s*=\s*#{ATTRIBUTE_VALUE.source})|(?<name>#{ATTRIBUTE_NAME.source}))/
    DYNAMIC_ATTRIBUTE = /(?:(?<name>#{ATTRIBUTE_NAME.source})\s*%=\s*#{ATTRIBUTE_VALUE.source})/
    ATTRIBUTES = /(?<attrs>(?:\s+#{ATTRIBUTE.source})*)/
    LITERAL_ATTRIBUTES = %i[path as yields collection].freeze
    PARTIAL_TAG = /(?<partial>_\w+)/
    PARTIAL = /(?:<#{PARTIAL_TAG.source}#{ATTRIBUTES.source}\s*>(?<content>.*?)<\/\k<partial>>)|(?:<#{PARTIAL_TAG.source}#{ATTRIBUTES.source}\s*\/>)/
    COMPONENT_TAG = /(?<component>[A-Z]\w+)/
    COMPONENT = /(?:<#{COMPONENT_TAG.source}#{ATTRIBUTES.source}\s*>(?<content>.*?)<\/\k<component>>)|(?:<#{COMPONENT_TAG.source}#{ATTRIBUTES.source}\s*\/>)/
    TEMPLATE = /(?:#{PARTIAL.source})|(?:#{COMPONENT.source})/m
    DYNAMIC_EXPRESSION = /^<%=([^%]*)%>$/

    class Theo
      def process(source)
        # Attributes
        source = source.gsub(DYNAMIC_ATTRIBUTE, '\k<name>="<%= \k<value> %>"')

        # Partials
        source.gsub(TEMPLATE) do |_|
          match = Regexp.last_match

          partial = match[:partial]
          component = match[:component]

          attributes = match[:attrs] || ''
          content = match[:content]

          attributes = process_attributes(attributes)

          path = attributes.delete(:path)

          collection = attributes.delete(:collection)
          as = attributes.delete(:as)

          yields = attributes.delete(:yields)
          yields = " |#{yields}|" if yields

          locals = attributes.empty? ? '' : attributes.map { |k, v| "'#{k}': #{v}" }.join(', ')

          if partial
            partial = partial.delete_prefix('_')

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
            component = "#{component}Component"

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

      def call(template, source = nil)
        theo = process(source)

        ::Rails.logger.info "Theo is generating ERB: \n#{theo}"

        ActionView::Template::Handlers::ERB.call(template, theo)
      end
    end
  end
end
