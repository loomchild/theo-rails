module Theo
  module Rails
    TX = '\s*([a-z0-9-]+-partial)\s*(.*?)(?<!%)'.freeze
    RX = %r{(?:<#{TX}>(.*?)</\1>)|(?:<#{TX}/>)}im
    LX = /\s*([^=%\s]+)\s*(?:(%)?=\s*"([^"]*)")?/
    RXA = /^<%=([^%]*)%>$/

    class Theo
      def process(source)
        source.gsub(RX) do |_|
          match = Regexp.last_match
          partial = (match[1] || match[4]).delete_suffix('-partial').underscore
          attributes = match[2] || match[5] || ''
          content = match[3]&.strip 

          attributes = attributes
            .scan(LX)
            .map { |name, literal, value| [name.to_sym, attribute(value || '', literal:)] }
            .to_h

          if attributes[:path]
            path = attributes.delete(:path).delete_prefix("'").delete_suffix("'")
            partial = "#{path}/#{partial}"
          end

          collection = ''
          if attributes[:collection]
            collection = attributes.delete(:collection).delete_prefix("'").delete_suffix("'")

            as = ''
            if attributes[:as]
              as = attributes.delete(:as).delete_prefix("'").delete_suffix("'")
              as = ", as: '#{as}'"
            end
            collection = ", collection: #{collection}#{as}"
          end

          arg = nil
          if attributes[:arg]
            arg = attributes.delete(:arg)
            raise 'arg %= syntax is required' if arg.start_with?("'")

            arg = "|#{arg}|"
          end

          if content
            output = "<%= render '#{partial}', {#{attributes.map {|k,v| "'#{k}': #{v}"}.join(', ')}} do #{ arg || '' } %>#{process(content)}<% end %>"
          else
            output = "<%= render partial: '#{partial}'#{collection}, locals: {#{attributes.map {|k,v| "'#{k}': #{v}"}.join(', ')}} %>"
          end

          output
        end
      end

      def attribute(source, literal: false)
        #TODO: support attributes like "a<%= b %>c

        return source if literal

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
