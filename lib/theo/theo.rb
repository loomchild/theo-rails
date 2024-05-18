module Theo
  ELEMENTS = %w(html base head link meta style title body address article aside footer header h1 h2 h3 h4 h5 h6 hgroup main nav section search blockquote dd div dl dt figcaption figure hr li menu ol p pre ul a abbr b bdi bdo br cite code data dfn em i kbd mark q rp rt ruby s samp small span strong sub sup time u var wbr area audio img map track video embed iframe object picture portal source svg math canvas noscript script del ins caption col colgroup table tbody td tfoot th thead tr button datalist fieldset form input label legend meter optgroup option output progress select textarea details dialog summary slot template)

  RX = %r{<\s*(?!(?:#{ELEMENTS.join('|')})[\s>])([a-z0-9_-]+)(.*?)(?<!%)>(.*?)</\1>}im
  LX = %r{\s*([^=]+?)\s*=\s*"([^"]*)"}

  RXA = %r{^<%=([^%]*)%>$}

  # RX = %r{(<\s*(?!#{ELEMENTS.join('|')})([a-z0-9_-]+)[^>]*>(.*?)</\1>)}i

  # XPATH="//*[not(#{ELEMENTS.map { |element| 'self::' + element }.join(' or ')})]"

  class Theo
    def process(source)
      source.gsub(RX) do |_|
        match = Regexp.last_match
        partial = match[1]
        content = match[3].strip

        locals = (match[2] || '')
          .scan(LX)
          .map { |name, value| [name.to_sym, attribute(value)] }
          .to_h

        p locals
        "<%= render '#{partial}', {#{locals.map {|k,v| "#{k}: #{v}"}.join(', ')}} do %>#{process(content)}<% end %>"
      end
    end

    def attribute(source)
      #TODO: support attributes like "a<%= b %>c

      match = RXA.match(source)
      p source
      p match
      p '---'
      return match[1] if match

      "'" + source + "'"
    end

    def call(template, source = nil)
      #theo = Nokogiri::HTML(source)

      #theo.xpath(XPATH).each do |node|
      #  p node
      #end

      #"'#{theo.to_html}'"

      #theo = source
      #  .gsub(RX, '<%= render "\1" do%>\2<% end %>')
      #  .gsub(RX, '<%= render "\1" do%>\2<% end %>')
        #.gsub(RX, '<%= render "\2" do%>\3<% end rescue "\1".html_safe %>')
      #"'AAAA' + render('btn') + 'BBBB'"

      theo = process(source)

      p theo

      ActionView::Template::Handlers::ERB.call(template, theo)
    end
  end
end
