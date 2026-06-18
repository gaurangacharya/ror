class ObfuscateEmail
  MAIL_TO = '&#109;&#97;&#105;&#108;&#116;&#111;&#58;'
  STYLE = 'unicode-bidi: bidi-override; direction: rtl;'

  def initialize(email)
    @email = email
  end

  def to_s
   "<script type=\"text/javascript\">" +
   " document.write('<a style=\"#{STYLE}\" href=\"#{MAIL_TO}#{obfuscated}\">#{reversed}</a>');" +
   "</script>"
  end

  private
  def obfuscated
    @email.gsub('@', '&#64;').gsub('.', '&#46;')
  end
  def reversed
    @email.each_char.to_a.reverse.join
  end
end
