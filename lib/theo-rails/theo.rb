module Theo
  module Rails
    AX = /(?<=\w)\s*%=\s*"(.*?)"(?=\s|>)/
    TX = '\s*([a-z0-9-]+-partial)\s*(.*?)(?<![%/])'.freeze # TODO: better > handling, in attribute values, allow ': handle as attribute*
    RX = %r{(?:<#{TX}>(.*?)</\1>)|(?:<#{TX}/>)}im
    LX = /\s*([^=%\s]+)\s*(?:=\s*"([^"]*)")?/
    RXA = /^<%=([^%]*)%>$/

    class Theo
      def process(source)
        # Attributes
        source = source.gsub(AX, '="<%= \1 %>"')

        p source

        # Partials
        source.gsub(RX) do |_|
          match = Regexp.last_match
          partial = (match[1] || match[4]).delete_suffix('-partial').underscore
          attributes = match[2] || match[5] || ''
          content = match[3]&.strip

          attributes =
            attributes
            .scan(LX)
            .map { |name, value| [name.to_sym, value || ''] }
            .to_h

          partial = "#{attributes.delete(:path)}/#{partial}" if attributes[:path]

          collection = ''
          if attributes[:collection]
            collection = attributes.delete(:collection)

            as = ''
            if attributes[:as]
              as = attributes.delete(:as)
              as = ", as: '#{as}'"
            end
            collection = ", collection: #{collection}#{as}"
          end

          arg = "|#{attributes.delete(:arg)}|" if attributes[:arg]

          attributes.transform_values! { |value| attribute(value) }

          if content
            output = "<%= render '#{partial}', {#{attributes.map {|k,v| "'#{k}': #{v}"}.join(', ')}} do #{arg || ''} %>#{process(content)}<% end %>"
          else
            output = "<%= render partial: '#{partial}'#{collection}, locals: {#{attributes.map {|k,v| "'#{k}': #{v}"}.join(', ')}} %>"
          end

          output
        end
      end

      def attribute(source)
        #TODO: support attributes like "a<%= b %>c

        match = RXA.match(source)
        return match[1] if match

        "'" + source + "'"
      end

      def call(template, source = nil)
        theo = process(source)

        ::Rails.logger.info "Theo is generating ERB: \n#{theo}"

        ActionView::Template::Handlers::ERB.call(template, theo)
      end
    end
  end
end
