class ThinkingSphinx::Wildcard
  def call
    query.gsub(extended_pattern) do
      pre, proper, post = $`, $&, $'
      # E.g. "@foo", "/2", "~3", but not as part of a token pattern
      is_operator = pre.match(%r{@$}) ||
                    pre.match(%r{([^\\]+|\A)[~/]\Z}) ||
                    pre.match(%r{(\W|^)@\([^\)]*$})
      # E.g. "foo bar", with quotes
      is_quote    = proper[/^".*"$/]
      has_star    = post[/\*$/] || pre[/^\*/]
      if is_operator || is_quote || has_star
        proper
      else
        # HACK: using prefix match instead of infix
        "#{proper}*"
      end
    end
  end
end
