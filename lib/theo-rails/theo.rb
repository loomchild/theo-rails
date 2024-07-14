module Theo
  module Rails
    ATTRIBUTE_NAME = /[\w\-:@]+/
    ATTRIBUTE_VALUE = /(?:(?:"(?<value>[^"]*)")|(?:'(?<value>[^']*)'))/
    ATTRIBUTE = /(?:(?:(?<name>#{ATTRIBUTE_NAME.source})\s*=\s*#{ATTRIBUTE_VALUE.source})|(?<name>#{ATTRIBUTE_NAME.source}))/
    DYNAMIC_ATTRIBUTE = /(?:(?<name>#{ATTRIBUTE_NAME.source})\s*%=\s*#{ATTRIBUTE_VALUE.source})/
    ATTRIBUTES = /(?<attrs>(?:\s+#{ATTRIBUTE.source})*)/
    PARTIAL_TAG = /(?<partial>[\w-]+-partial)/
    PARTIAL = /(?:<#{PARTIAL_TAG.source}#{ATTRIBUTES.source}\s*>(?<content>.*?)<\/\k<partial>>)|(?:<#{PARTIAL_TAG.source}#{ATTRIBUTES.source}\s*\/>)/im
    DYNAMIC_EXPRESSION = /^<%=([^%]*)%>$/

    class Theo
      def process(source)
        # Attributes
        source = source.gsub(DYNAMIC_ATTRIBUTE, '\k<name>="<%=\k<value>%>"')

        # Partials
        source.gsub(PARTIAL) do |_|
          match = Regexp.last_match
          partial = (match[:partial]).delete_suffix('-partial').underscore
          attributes = match[:attrs] || ''
          content = match[:content]&.strip

          attributes =
            attributes
            .gsub(ATTRIBUTE)
            .map { Regexp.last_match }
            .map { |attr| [attr[:name].to_sym, attr[:value] || ''] }
            .to_h

          partial = "#{attributes.delete(:path)}/#{partial}" if attributes[:path]

          collection = ''
          if attributes[:collection]
            collection = attribute(attributes.delete(:collection))

            as = ''
            if attributes[:as]
              as = attributes.delete(:as)
              as = ", as: '#{as}'"
            end
            collection = ", collection: #{collection}#{as}"
          end

          yields = "|#{attributes.delete(:yields)}|" if attributes[:yields]

          attributes.transform_values! { |value| attribute(value) }

          if content
            output = "<%= render '#{partial}', {#{attributes.map {|k,v| "'#{k}': #{v}"}.join(', ')}} do #{yields || ''} %>#{process(content)}<% end %>"
          else
            output = "<%= render partial: '#{partial}'#{collection}, locals: {#{attributes.map {|k,v| "'#{k}': #{v}"}.join(', ')}} %>"
          end

          output
        end
      end

      def attribute(source)
        # TODO: support attributes like "a<%= b %>c

        match = DYNAMIC_EXPRESSION.match(source)
        return match[1] if match

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
