module Theo
  RX = %r{<\s*([a-z0-9-]+-partial)\s*(.*?)(?<!%)>(.*?)</\1>}im
  LX = %r{\s*([^=]+?)\s*(%)?=\s*"([^"]*)"}
  RXA = %r{^<%=([^%]*)%>$}

  class Theo
    def process(source)
      source.gsub(RX) do |_|
        match = Regexp.last_match
        partial = match[1].delete_suffix('-partial')
        content = match[3].strip

        locals = (match[2] || '')
          .scan(LX)
          .map { |name, literal, value| [name.to_sym, attribute(value, literal:)] }
          .to_h

        "<%= render '#{partial}', {#{locals.map {|k,v| "#{k}: #{v}"}.join(', ')}} do %>#{process(content)}<% end %>"
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

      Rails.logger.info "Theo is generating ERB: \n#{theo}"

      ActionView::Template::Handlers::ERB.call(template, theo)
    end
  end
end
