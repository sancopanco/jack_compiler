module JackAnalyzer
  module XmlBuilder
    def self.to_xml(tokens)
      str = ['<tokens>']
      tokens.each do |token|
        str << "<#{token.type}>#{get_html_string(token)}</#{token.type}>"
      end
      str << '</tokens>'
      str.join("\n")
    end

    def self.get_html_string(token)
      return token.literal if token.type == TokenType::STING_CONST || token.type == TokenType::INT_CONST
      return '&lt;' if token.lexeme == '<'
      return '&gt;' if token.lexeme == '>'
      return '&quot' if token.lexeme == '"'
      return '&amp;' if token.lexeme == '&'
      token.lexeme
    end
  end
end
